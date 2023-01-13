function [data,unusedBytes,samplesProcessedPerDetector]=translateNinja2022Bytes(inputBytes,stateMap)
% data is the translated data output. It has 3 dimensions: 1 is time
% (samples) 2 is detectors; the third dimension is the state number, which
% could be a proxy for detector number if the state acquisition sequence is
% source by source (well, detector number and wavelength)
raw=inputBytes;
%% constants
% some of these might need to be updated dynamically in the future when
% there are multiple detector boards, I am not sure

N_DETECTOR_BOARDS=1; %there should be a way dynamic way to find this number

header_indicator=254; %byte indicating the header
detector_header_indicator=[253,252]; %bytes indicating the detector header
state_number_length=2;
sample_counter_length=1;

%these two might remain constants forever
N_DET_PER_BOARD = 8;
N_BYTES_PER_DET = 3;

N_DETECTORS=N_DET_PER_BOARD*N_DETECTOR_BOARDS;

payloadSize=N_DET_PER_BOARD*N_BYTES_PER_DET;
offset=length(header_indicator)+state_number_length+length(detector_header_indicator)+sample_counter_length; %offset for first payload byte
packageLength=offset+payloadSize+1;  %I am not sure what the last byte is for, supposed to be checksum

%% start the translation

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

%move the indicators to mark the FPGA header instead
indicator=indicator-length(detector_header_indicator)-state_number_length;

%find if the last data package is complete
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

unusedBytes=raw(lastByteUsed+1:end);

%ignore potential indicators that are less than one data package away from
%the end of the captured data

offset=length(header_indicator)+state_number_length+length(detector_header_indicator)+sample_counter_length; %offset for first payload byte
ii=1;
indicator_matrix=indicator+offset+(0:N_BYTES_PER_DET:(N_DET_PER_BOARD*N_BYTES_PER_DET)-1);
A=raw(ii-1+indicator_matrix)*256^(ii-1);
for ii=2:N_BYTES_PER_DET
    A=A+raw(ii-1+indicator_matrix)*256^(ii-1);
end

%negative value correction
A = (A > 2^23-1).*2^24 - A;

%% identify what detector board the data came from
detectorBoardId=raw(indicator+length(header_indicator))+1;

% find how many samples I got per detector board
tableOfSamplesPerBoard=tabulate(detectorBoardId);
maxNumOfSamples=max(tableOfSamplesPerBoard(:,2));

B=nan(maxNumOfSamples,N_DETECTORS); %reorganize by detector number

%easiest way of doing it is looping row by roow of A and moving the data to
%the appropriate column of B. This is probably going to be innefficient.
%Maybe there is a more efficicent way to do it, maybe by local indexing 

samplesProcessedPerDetector=zeros(1,N_DETECTORS);

for ki=1:N_DETECTOR_BOARDS
    logicalIndicesOfDetectork=detectorBoardId==ki;
    samplesProcessedPerDetector((1:N_DET_PER_BOARD)+N_DET_PER_BOARD*(ki-1))=sum(logicalIndicesOfDetectork);
    B(1:samplesProcessedPerDetector(ki),(1:N_DET_PER_BOARD)+N_DET_PER_BOARD*(ki-1))=...
        A(logicalIndicesOfDetectork,:);
end

%% identify number of states
%estados=1+raw(indicator+length(header_indicator)+1); %this is how it
%should be done when we have the whole bytestream. For a partial
%bytestream, we should instead read from the statemap
%number of states
foo=find(stateMap(:,27)==1);
N_STATES=foo(1);
states=1:N_STATES;

%% now sort them by state

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
