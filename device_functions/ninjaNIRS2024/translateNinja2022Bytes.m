function [data,unusedBytes,darkLevelAvg]=translateNinja2022Bytes(inputBytes,stateMap,N_DETECTOR_BOARDS,acc_active,aux_active)
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

% N_DETECTORS=N_DET_PER_BOARD*N_DETECTOR_BOARDS;
% 
% offsetBoard=N_DET_PER_BOARD*N_BYTES_PER_DET+length(detector_header_indicator)+sample_counter_length+1;
% payloadSize=N_DETECTOR_BOARDS*offsetBoard;
% offset=length(header_indicator)+state_number_length; %offset for first payload byte
% packageLength=offset+payloadSize;  

N_DETECTORS=N_DET_PER_BOARD*N_DETECTOR_BOARDS;

offsetBoard=N_DET_PER_BOARD*N_BYTES_PER_DET+length(detector_header_indicator)+sample_counter_length+1;
if acc_active
    acc_bytes = 18;
else
    acc_bytes = 0;
end
if aux_active
    aux_bytes = 8;
else
    aux_bytes = 0;
end
payloadSize=N_DETECTOR_BOARDS*offsetBoard;
offset=length(header_indicator)+state_number_length+aux_bytes; %offset for first payload byte
packageLength=offset+payloadSize+acc_bytes;  

%% find detector header indicators
endByte=0;

%first identify the end byte of the package
indicator=find(raw==endByte);
indicator(indicator<packageLength)=[];

%now find which ones start with 254
indicator=indicator(raw(indicator+1-packageLength)==header_indicator);

%move indicators to start of package
indicator=indicator-packageLength+1;

%now make sure the detector header indicators are in the correct position
for ki=1:N_DETECTOR_BOARDS
    indicator=indicator(raw(indicator+offset+offsetBoard*(ki-1))==detector_header_indicator(1));
    indicator=indicator(raw(indicator+offset+1+offsetBoard*(ki-1))==detector_header_indicator(2));
end
% if length(unique(diff(indicator)))>1
%     disp('stop')
% end


%the previous test should be repeated if multiple detector boards for better
%accuracy; otherwise there will be misidentified packages

%% identify number of states in data read
estados=1+raw(indicator+length(header_indicator));
states=unique(estados);

%use the states to figure out if there is a packet that shouldn't be a
%packet
statesToEliminate=[false;diff(states)~=1];
if sum(statesToEliminate)>0
    %then there is a problem with the data
    foo = states(statesToEliminate);
    for iFoo = 1:length(foo)
        toEliminate=estados==foo(iFoo);
        indicator(toEliminate)=[];
    end
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

%% translate Temparature, Gyroscope and Accelarometer data
TGAdata = [];
if acc_active
    indicator_matrix = indicator+offset+N_DETECTOR_BOARDS*(N_DET_PER_BOARD*N_BYTES_PER_DET+length(detector_header_indicator)+sample_counter_length+1)+sample_counter_length+2;
    TGAdata = raw(indicator_matrix+(0:2:13))+256.*raw(indicator_matrix+(1:2:13));
    TGAdata = TGAdata - (TGAdata > 2^15-1).*2^16;
    TGAdata(:,1) = TGAdata(:,1)/256+25;
    TGAdata(:,2:4) = TGAdata(:,2:4)*250./(2^15-1);
    TGAdata(:,5:7) = TGAdata(:,5:7)*4./(2^15-1);
end
%% identify number of states
%estados=1+raw(indicator+length(header_indicator)+1); %this is how it
%should be done when we have the whole bytestream. For a partial
%bytestream, we should instead read from the statemap
%number of states
estados=1+raw(indicator+length(header_indicator));
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
    dataOrganizedByState(1:lengthStateki(ki),:,ki)=B(~~isStateki(:,ki),:);  %<-- CHECK THIS WORKS AS INTENDED FOR MORE THAN ONE DETECTOR BOARD
end

%% identify dark states
darkStateIdx=~any(stateMap(states,19:21),2);
% sort dark states by detector
darkSamplesbyState=dataOrganizedByState(:,:,darkStateIdx);
% summarize dark state intensity for each detector
darkLevelAvg=nanmean(nanmean(darkSamplesbyState,3),1);

%% output

data=dataOrganizedByState;
