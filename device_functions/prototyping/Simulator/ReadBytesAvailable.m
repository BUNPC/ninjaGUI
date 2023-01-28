function [dataoutput,packlen,remainderbytes,datac,statusdata,maxvout,avgvout]=ReadBytesAvailable(app)
% Used to read the serial port and translate it to Matlab format
% s is the serial port object.
% dev is there just to specify the number of detectors and auxs
% SD is the sd struct to determine which channels we are actually
% interested in
% fID is there for now to save the binary data to file; consider removing
% in the future when I make sure the real time function works correctly
% dataoutput is the intensity data of the fNIRS and aux channels: it
% contains all aux channels but only the fNIRS channels specified in the
% measurement list
% packlen says how many samples were collected for each channel;
% unfortunately, they are rarely the same, which complicates the work for
% the main GUI;
% datac contains the complex data of all channels; the GUI is not doing
% anything with it, but in a future implementation it could be used for
% complex averaging etc
% statusdata contains the information in the status data packages
% remainderbytes returns unusued bytes from the stream; this is useful in
% case a data package is incomplete; these bytes should be added to the
% beginning of the new data stream
% fID is used to stream the serial bytes straight to file in
% case there is an application crash. That way the data can be recovered.
% maxvout returns the maximum value for each optode. avgout returns the
% average value for each optode; these two can be used for saturation
% purposes

%% parse app variables

s=app.sp;
dev=app.deviceInformation;
SD=app.nSD;
prevrbytes=app.rbytes;
fID=app.fstreamID;
ML=SD.measList;
fs=app.rate;

%% hardware constants
N_OPTODES=dev.nDets;
N_WORDS_PER_DFT = 2;
N_BYTES_IN_DFT_WORD = 5;
N_FREQ = 8;
N_AUX = dev.nAux;
N_BYTES_PER_AUX = 2;
N_ONBOARD_AUX=2;  %the current firmware has 2 AUX on board, the rest are remote

N_BYTES_TO_READ_PER_SAMPLE=N_WORDS_PER_DFT * N_BYTES_IN_DFT_WORD * (N_FREQ+1) +5; % N_FREQ+1 : for max/avg data; +3 for [channel, #bytes, DFT count];

%% DFT constants and data offsets

DFT_N=1024;
KD = [56 60 64 70 80 84 96 105]; % demodulation k

offsetA = (0:N_FREQ-1)*N_BYTES_IN_DFT_WORD*N_WORDS_PER_DFT +3;
offsetB=offsetA+N_BYTES_IN_DFT_WORD;
wordpos=1:N_BYTES_IN_DFT_WORD;
part1=wordpos+offsetA';
part2=wordpos+offsetB';
part3=max(part2(:));
part4=part3 + N_BYTES_IN_DFT_WORD;
powso256=256.^(0:N_BYTES_IN_DFT_WORD-1);
Kernel=exp(-1i*(2*pi/DFT_N)*KD(1:N_FREQ));

%% read bytes available as a multiple of bytes in the buffer and number of optodes (and aux)
ba=s.NumBytesAvailable;

%this code helps prevent reading incomplete data packages
npacks=30;   %making this constant larger means we read more packets at a time, reducing processing overhead, but making it too large will affect refresh rate
rb=floor(ba/N_BYTES_TO_READ_PER_SAMPLE/(N_OPTODES+1)/npacks)*N_BYTES_TO_READ_PER_SAMPLE*(N_OPTODES+1)*npacks;

if rb>0
    raw = read(s,rb,'uint8')';
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


%% find indicator bytes
indicator=find(raw==N_BYTES_TO_READ_PER_SAMPLE-2);
indicator=indicator((indicator+N_BYTES_TO_READ_PER_SAMPLE-2)<=rawN); %only consider  potentially complete packages
packC=indicator-1;   %potential initial positions of data packets
packC(packC==0)=[];  %this means we missed the initial byte of one data packet

%% now, segregate candidate packages on data, aux or status

pAuxp=packC(raw(packC)==200); %possible aux positions
pRemp=packC(raw(packC)==201); %possible remote board positions
pStatp=packC(raw(packC)==254); %possible Status positions
pDatap=packC(raw(packC)>=0&raw(packC)<N_OPTODES); %possible detector positions


%% now look for the stop bytes; if they don't have them, then they are not data packages
%these are way more likely to be the actual positions of the data packages
pAux=pAuxp(raw(pAuxp+N_BYTES_TO_READ_PER_SAMPLE-2,:)==171&raw(pAuxp+N_BYTES_TO_READ_PER_SAMPLE-1,:)==171);
pStatp=pStatp(raw(pStatp+N_BYTES_TO_READ_PER_SAMPLE-2,:)==172&raw(pStatp+N_BYTES_TO_READ_PER_SAMPLE-1,:)==172);
pDatap=pDatap(raw(pDatap+N_BYTES_TO_READ_PER_SAMPLE-2,:)==170&raw(pDatap+N_BYTES_TO_READ_PER_SAMPLE-1,:)==170);
pRemp=pRemp(raw(pRemp+N_BYTES_TO_READ_PER_SAMPLE-2,:)==170&raw(pRemp+N_BYTES_TO_READ_PER_SAMPLE-1,:)==170);



%% initialize databuffer



%% now find the remainder bytes, that is, those that were unusued because they likely were part of an incomplete package

finalbyteused=max([pAux;maxdatapackpos;pStatp;pRemp])+N_BYTES_TO_READ_PER_SAMPLE-1;
remainderbytes=raw(finalbyteused+1:end); %these bytesshould be appended to beggining of next stream


%% finally, prepare data output

avgvout=avgvout(:,~all(isnan(avgvout)));
maxvout=maxvout(:,~all(isnan(maxvout)));

dataoutput=[data;auxb;auxrem];
dataoutput=dataoutput(:,~all(isnan(dataoutput))); %eliminate columns with no data

packlen=sum(~isnan(dataoutput),2);  %number of samples in data package