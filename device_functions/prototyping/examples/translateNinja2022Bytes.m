function [data,unusedBytes]=translateNinja2022Bytes(inputBytes,stateMap,N_DETECTOR_BOARDS)
% data is the translated data output. It has 3 dimensions: 1 is time
% (samples) 2 is detectors; the third dimension is the state number, which
% could be a proxy for detector number if the state acquisition sequence is
% source by source (well, detector number and wavelength)
raw=inputBytes;
%% constants
% some of these might need to be updated dynamically in the future when
% there are multiple detector boards, I am not sure

header_indicator=254; %byte indicating the header
detector_header_indicator=[253,252]; %bytes indicating the detector header
state_number_length=2;
sample_counter_length=1;

%these two might remain constants forever
N_DET_PER_BOARD = 8;
N_BYTES_PER_DET = 3;

N_DETECTORS=N_DET_PER_BOARD*N_DETECTOR_BOARDS;

offsetBoard=N_DET_PER_BOARD*N_BYTES_PER_DET+length(detector_header_indicator)+sample_counter_length+1;
payloadSize=N_DETECTOR_BOARDS*offsetBoard;
offset=length(header_indicator)+state_number_length; %offset for first payload byte
packageLength=offset+payloadSize;  

%% find detector header indicators
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

%move the indicators to mark the FPGA header instead
indicator=indicator-length(detector_header_indicator)-state_number_length;

%% identify number of states in data read
estados=1+raw(indicator+length(header_indicator)+1);
states=unique(estados);

%use the states to figure out if there is a packet that shouldn't be a
%packet
statesToEliminate=[false;diff(states)~=1];
if sum(statesToEliminate)>0
    %then there is a problem with the data
    toEliminate=estados==states(statesToEliminate);
    indicator(toEliminate)=[];
    %do states again
    estados=1+raw(indicator+length(header_indicator)+1);
    states=unique(estados);
end


%% figure out if last package is incomplete

if (indicator(end)+packageLength-1)>length(raw)
    %if the last package indicator detected is for a package that was not
    %read in its totality, then remove this indicator and use it to mark
    %the position of the last used byte
    lastByteUsed=indicator(end)-1;
    indicator(end)=[];
    estados(end)=[];
else
    %this to cover the possibility that the final package marker was not
    %identified if we only captured the headers partially
    positionOfIncompleteHeader=indicator(end)+packageLength;
    lastByteUsed=positionOfIncompleteHeader-1;
end

%ignore potential indicators that are less than one data package away from
%the end of the captured data

unusedBytes=raw(lastByteUsed+1:end);

%% translate

B=nan(length(indicator),N_DETECTORS); 

for ki=1:N_DETECTOR_BOARDS
    ii=1;

    indicator_matrix=indicator+offset+(0:N_BYTES_PER_DET:(N_DET_PER_BOARD*N_BYTES_PER_DET)-1)+(ki-1)*offsetBoard+length(detector_header_indicator)+sample_counter_length;
    A=raw(ii-1+indicator_matrix)*256^(ii-1);
    for ii=2:N_BYTES_PER_DET
        A=A+raw(ii-1+indicator_matrix)*256^(ii-1);
    end

    %negative value correction
    A = (A > 2^23-1).*2^24 - A;
    B(:,(1:N_DET_PER_BOARD)+(ki-1)*N_DET_PER_BOARD)=A;
end


%% identify number of states
%estados=1+raw(indicator+length(header_indicator)+1); %this is how it
%should be done when we have the whole bytestream. For a partial
%bytestream, we should instead read from the statemap
%number of states
estados=1+raw(indicator+length(header_indicator)+1);
foo=find(stateMap(:,27)==1);
N_STATES=foo(1);
states=1:N_STATES;

%% now sort data by state

isStateki=zeros(length(indicator),N_STATES);
lengthStateki=zeros(1,N_STATES);
for ki=1:N_STATES
    isStateki(:,ki)=estados==ki;
    lengthStateki(ki)=sum(isStateki(:,ki));    
end

%find which state got the most samples
maxSamples=max(lengthStateki);

dataOrganizedByState=nan(maxSamples,N_DET_PER_BOARD*N_DETECTOR_BOARDS,N_STATES);

for ki=1:N_STATES
    dataOrganizedByState(1:lengthStateki(ki),:,ki)=B(~~isStateki(:,ki),:);  %<-- this will break or will be bugged if there is more than one detector board, change the logic
end


%% output

data=dataOrganizedByState;
