function [data,N_STATES]=translateNinja2022Bytes(inputBytes)

raw=inputBytes';

% raw=inputBytes(1:1000);
% 
% %first sample of the header must be 254, second are third are state number,
% %and fourth and fifth are [253,252]
% 
% %254 is the FPGA header. Can it vary?
% %[253,252] is the detector board header. Can it vary? I currently only have
% %one detector board and one source board. The source board has 4 sources
% %and the detector board has 8 detectors
% 
% %data packages seem to be 31 bytes, thus 26 when removing the header. But
% %still there is the sample counter, status flag (?), payload and checksum.
% %I don't yet know how long each is
% 
% % sixth byte is sample counter, apparently there is only one byte for this,
% % so now 25 bytes left
% 
% 
% N_DETBOARDS = 1;
% N_DET_PER_BOARD = 8;
% val = zeros(1,N_DETBOARDS*N_DET_PER_BOARD); %used to store the value for each detector
% 
% % each detector returns 3 bytes
% N_BYTES_PER_DET = 3;
% 
% % so payload seems to be N_DETBOARDS*N_DET_PER_BOARD*N_BYTES_PER_DET=24
% % bytes
% 
% % so only one byte remains, not sure if at start or end, so either status
% % flag or checksum are not used
% 
% 
% N_STATES = 2;
% 
% N_BYTES_TO_READ_PER_DETB = N_DET_PER_BOARD*N_BYTES_PER_DET + 4;
% N_BYTES_TO_READ_PER_HEADER = 3;
% 
% % so, each detector board is 28 bytes; 24 bytes of payload 2 of header and
% % 2 of ???
% 
% OFFSET_ARRAY = 0:N_BYTES_TO_READ_PER_DETB:((N_DETBOARDS-1)*N_BYTES_TO_READ_PER_DETB);
% OFFSET_ARRAY_RES = OFFSET_ARRAY + (0:N_BYTES_PER_DET:((N_DET_PER_BOARD-1)*N_BYTES_PER_DET))';
% OFFSET_ARRAY_RES = OFFSET_ARRAY_RES(:)'+N_BYTES_TO_READ_PER_HEADER;
% 
% 
% %so, in this example, the data bytes are from 7 to 30; the first three are
% %for the first detector, second three for the second detector and so on
% % byte 4 is the least significant and byte 6 is the most significant
% 
% %this reads the data from the first detector board and translates it to a DL
% for ii = 1:N_BYTES_PER_DET
%         val = val + 256^(ii-1)*raw(3 + ii + OFFSET_ARRAY_RES);
% end
% 
% val = (val > 2^23-1).*2^24 - val;
% 
% % 

%% constants
% some of these might need to be updated dynamically in the future when
% there are multiple detector boards, I am not sure

header_indicator=254; %byte indicating the header
detector_header_indicator=[253,252]; %bytes indicating the detector header
state_number_length=2;
sample_counter_length=1;

N_DET_PER_BOARD = 8;
N_BYTES_PER_DET = 3;
payloadSize=N_DET_PER_BOARD*N_BYTES_PER_DET;
offset=length(header_indicator)+state_number_length+length(detector_header_indicator)+sample_counter_length; %offset for first payload byte
packageLength=offset+payloadSize+1;  %I am not sure what the last byte is for

%% now I can start prototyping the actual translator

%find detector header indicators
indicator=find(raw==detector_header_indicator(end)); %find header indicators
for ki=1:length(detector_header_indicator)-1
    indicator=indicator(raw(indicator-ki)==detector_header_indicator(end-ki));    
end

%now indicator has potential data packages identified based on the last
%byte of the detector header; now find if there is the FPGA header too

indicator=indicator( ...
    raw( ...
    indicator-length(detector_header_indicator)-state_number_length)...
    ==header_indicator);

%move the indicator to mark the start of the packages
indicator=indicator-length(detector_header_indicator)-state_number_length;

raw(indicator+4);

%figure out if last package is incomplete
if (indicator(end)+packageLength-1)>length(raw)
    %if the last package indicator detected is for a package that was not
    %read in its totality, then remove this indicator and use it to mark
    %the position of the last used byte
    lastByteUsed=indicator(end)-1;
    indicator(end)=[];
else
    %this to cover the possibility that the final package marker was not
    %identified if we only captured the headers partially
    positionOfIncompleteHeader=indicator(end)+packageLength;
    lastByteUsed=positionOfIncompleteHeader-1;
end

remainderBytes=raw(lastByteUsed+1:end);


%ignore potential indicators that are less than one data package away from
%the end of the captured data

ii=1;
indicator_matrix=indicator+offset+(0:N_BYTES_PER_DET:(N_DET_PER_BOARD*N_BYTES_PER_DET)-1);
A=raw(ii-1+indicator_matrix)*256^(ii-1);
for ii=2:N_BYTES_PER_DET
    A=A+raw(ii-1+indicator_matrix)*256^(ii-1);
end

%negative value correction
A = (A > 2^23-1).*2^24 - A;

%% identify number of states
estados=1+raw(indicator+length(header_indicator)+1);
states=unique(estados);

%maybe add some code to make sure the numbers are sequential
statesToEliminate=[false;diff(states)~=1];
if sum(statesToEliminate)>0
    %then there is a problem with the data
end

N_STATES = length(states);

%% now sort them by state

isStateki=zeros(length(indicator),N_STATES);
lengthStateki=zeros(1,N_STATES);
for ki=1:N_STATES
    isStateki(:,ki)=estados==ki;
    lengthStateki(ki)=sum(isStateki(:,ki));    
end

%find which state got the most samples
maxSamples=max(lengthStateki);

dataOrganizedByState=nan(maxSamples,N_DET_PER_BOARD,N_STATES);

for ki=1:N_STATES
    dataOrganizedByState(1:lengthStateki(ki),:,ki)=A(~~isStateki(:,ki),:);
end

%foo=dataOrganizedByState(:,:,1)-dataOrganizedByState(:,:,2);


%% assign each state to its correct channel based on the state


%% output

data=dataOrganizedByState;
