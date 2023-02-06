function [dataoutput,packlen,remainderbytes]=ReadBytesAvailable(app)
% Used to read the data sent from the instrument and translate it to a a
% matlab array. The only input is app, which is the structure containing
% the GUI variables. The specific implementation of this function will use
% whichever app properties are useful or necessary to calculate the
% required outputs

%all outputs [dataoutput,packlen,remainderbytes,datac,statusdata,maxvout,avgvout]
% The required outputs for this functions to interact
% correctly with the GUI are:
% dataoutput is the data of the fNIRS and aux channels: channels in the
% array need to be sorted the same was as in the measurement list, with
% time or samples across columns, channels across rows
% packlen says how many samples were collected for each channel;
% this could be a scalar if all channels acquired the same number of
% channels in the iteration, but in general is an array in which each
% element specifies how many samples were acquired at each channel and
% wavelength
% remainderbytes needs to contain the bytes that were read but not used in
% the current iteration because if the data read operation did not return a
% discrete number of data packages. This way they can be appended to the
% start of the bytestream read in the next read opperation

% optional outpus (the GUI won't break if they are not returned)
% datac contains the complex data of all channels if available; this was
% something that was proposed for frequency multiplexed systems, but in the
% end we have not used it and the GUI does nothing to these data
% statusdata contains the information in the status data packages, if
% available; but the GUI currently does nothing with them
% maxvout returns the maximum value for each optode. avgout returns the
% average value for each optode; these two can be used for saturation
% purposes. avgout must be returned if the hardware configuration specifies
% that the hardware is able to measure and display through the GUI which
% optodes are saturared (field 'optodeSaturationThreshold' from the config
% file)

%current implementation ignores optional outputs
subtractDark=1;

%% parse app variables

s=app.sp; %serial port
dev=app.deviceInformation; %config file
SD=app.nSD; %probe file
prevrbytes=app.rbytes; %remainder bytes from the previous read operation
fID=app.fstreamID;  %file streamer for debug mode; this can be used to stream the bytes directly to file as a backup

%% read serial buffer opperations.
% It is setup so the read operation reads all bytes available in the serial
% buffer; however, there needs to be a minimum amount of bytes in the
% buffer for the operation to be performed; if there is less than some
% number of bytes, the function will end with no read operations and the
% bytes will be read in the next iteration. This is so the function is not
% called multiple times to read just one byte, which I think makes
% acquisition more efficient
ba=s.NumBytesAvailable;

rb=30000; %minimum number of bytes to read per operation

if ba>rb
    raw = read(s,ba,'uint8')';
    if ~isempty(fID)
        fwrite(fID,raw,'uchar');
    end
else
    dataoutput=[];
    maxvout=[];
    avgvout=[];
    packlen=0;
    datac=[];
    statusdata=[];
    remainderbytes=prevrbytes;
    return;
end

raw=[prevrbytes;raw];
rawN=size(raw,1);

%% translate data to a numeric array
[B,unusedBytes]=translateNinja2022Bytes(raw,app.deviceInformation.stateMap,app.deviceInformation.nDetBoards);

%circshift to the left in the third dimension since packets marked as 1
%actually store the last state, packets marked as 2 are state 1 etc

B=circshift(B,-1,3);

% Nstates=size(B,3);
% fs=1e3/Nstates;

% B is organized as time by detector by state; for this implementation, the
% subfunction to translate the bytes needs to handle things like the not
% getting the same number of samples for each 
% The first dimension of B will be number of samples acquired for the
% channel with more samples in this read operation. second dimension is the
% number of detectors. Third dimension are the states. Unacquired samples
% will be stored as nan values


%% code to go from detector and state number to positions in the measurement list

indices=app.deviceInformation.stateIndices; %this is calculated when the state is setup
%indices is not what it should be optimally. Right now it's first column
%state, second column detector

organizedData=nan(size(B,1),size(SD.measList,1));
% for loop is likely not the best way to do it

nStates=size(B,3);
cumDark=0;
for ki=1:size(SD.measList,1)    
    try
        organizedData(:,ki)=B(:,indices(ki,2),indices(ki,1));        
        if subtractDark
            darkState=B(:,indices(ki,2),indices(ki,1)+1);
            %subtracts the adjacent state (after the current). Assumes
            %there is a dark state between each active state
            organizedData(:,ki)=organizedData(:,ki)-darkState;
            cumDark=cumDark+mean(darkState);
        end
        
    end
end

%% truncate to positive
organizedData(organizedData<1)=1;

%% assign all outputs
dataoutput=organizedData';
packlen=sum(~isnan(dataoutput),2);  %number of samples in data package
remainderbytes=unusedBytes;

