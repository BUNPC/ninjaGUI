function [dataoutput,packlen,remainderbytes,datac,statusdata]=ninja_ReadBytesAvailable(s,dev,SD,prevrbytes,fID)
% Reads the serial port for a ninjaNIRS 2021a device. 
% The firmware for this version is very different and it's based on NIRS1k
% with some differences, such as customizable frequencies and two power
% levels for the LEDs. Thus, this function is almost a copy/paste of the
% NIRS1k function.
%s is the serial port object.
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


%% hardware constants
N_OPTODES=dev.nDets;
N_WORDS_PER_DFT = 2;
N_BYTES_IN_DFT_WORD = 5;
N_FREQ = 8;
N_AUX = dev.nAux;
N_BYTES_PER_AUX = 2;

N_BYTES_TO_READ_PER_SAMPLE=N_WORDS_PER_DFT * N_BYTES_IN_DFT_WORD * (N_FREQ+1) +5; % N_FREQ+1 : for max/avg data; +3 for [channel, #bytes, DFT count];

%% DFT constants and data offsets

DFT_N=1024;
KD = [56 60 64 70 80 84 96 105]; % demodulation k

offsetA = (0:N_FREQ-1)*N_BYTES_IN_DFT_WORD*N_WORDS_PER_DFT +3;
offsetB=offsetA+N_BYTES_IN_DFT_WORD;
wordpos=1:N_BYTES_IN_DFT_WORD;
part1=wordpos+offsetA';
part2=wordpos+offsetB';
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
pStatp=packC(raw(packC)==254); %possible Status positions
pDatap=packC(raw(packC)>=0&raw(packC)<N_OPTODES); %possible detector positions


%% now look for the stop bytes; if they don't have them, then they are not data packages
%these are way more likely to be the actual positions of the data packages
pAux=pAuxp(raw(pAuxp+N_BYTES_TO_READ_PER_SAMPLE-2,:)==171&raw(pAuxp+N_BYTES_TO_READ_PER_SAMPLE-1,:)==171);
pStatp=pStatp(raw(pStatp+N_BYTES_TO_READ_PER_SAMPLE-2,:)==172&raw(pStatp+N_BYTES_TO_READ_PER_SAMPLE-1,:)==172);
pDatap=pDatap(raw(pDatap+N_BYTES_TO_READ_PER_SAMPLE-2,:)==170&raw(pDatap+N_BYTES_TO_READ_PER_SAMPLE-1,:)==170);



%% initialize databuffer
ML=SD.measList;

maxsampN=ceil(length(pDatap)/N_OPTODES)+3; %max number of samples possibly contained in the data package
datac=complex(nan(N_OPTODES,maxsampN,N_FREQ)); %complex data buffer
auxb=nan(N_AUX,maxsampN);  %aux data buffer

data=nan(size(ML,1),maxsampN); %buffer for intensity data


%% decode the optode data packets
databm=complex(nan(maxsampN,N_FREQ));
maxdatapackpos=0;
for k=0:N_OPTODES-1
    indik=pDatap(raw(pDatap)==k);  %contain the indices of the potential data packages on raw for optode k
    seqk=raw(min(indik+2,end));  %contains the sequence data of potential data package; real data packages should be on a consecutive sequence
    
    dseqk=diff(seqk);
    sbreaks=find(dseqk~=1&dseqk~=-255); %sequence breaks
    if dseqk(1)==1  
        sbreaks=sbreaks(2:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
    else
        %in the unlikely case the first packet was the sequence breaking one
        sbreaks=sbreaks(1:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
    end
    
    dataindk=indik;
    dataindk(sbreaks)=[];  %remove the sequence breaking packages
    
    
    maxdatapackpos=max(max(maxdatapackpos),max(dataindk)); %this variable will be used to find where the unused bytes are, so we can use them next iteration
    
    %the previous code is also potentially losing the last data point, but
    %1) doing that prevents errors, 2) it also prevents errors in the
    %likely case that it was truncated
    
    
    %% now, for each element of dataindk...
    mLength=size(dataindk,1);
    databm=databm*nan;
    for m=1:mLength
        %% I need to actually convert the data package to intensity data
        indi1=dataindk(m):(dataindk(m)+N_BYTES_TO_READ_PER_SAMPLE-1); %indices for package
        if all(indi1<=rawN)  %this check is to avoid incomplete data packages
            rawp=raw(indi1,:);
            %transform raw data to complex FT
            pnm1=sum(rawp(part1).*powso256,2)';
            indi=pnm1>(2^39-1);
            pnm1(indi)=pnm1(indi)-2^40;
            pnm0=sum(rawp(part2).*powso256,2)';
            indi=pnm0>(2^39-1);
            pnm0(indi)=pnm0(indi)-2^40;
            databm(m,:)=pnm0 - Kernel.*pnm1;
        end
    end
    datac(k+1,:,:)=databm;
end

%% now decode the aux data packets

%discard incomplete aux packets
pAux(pAux+2>rawN)=[];


seqAux=raw(pAux+2);  %contains the sequence data of potential aux packets
dseqAux=diff(seqAux);
sbreaks=find(dseqAux~=1&dseqAux~=-255); %sequence breaks

if dseqAux(1)==1  
        sbreaks=sbreaks(2:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
    else
        %in the unlikely case the first packet was the sequence breaking one
        sbreaks=sbreaks(1:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
end

pAux(sbreaks)=[]; %remove the sequence breaking packages from consideration


pows256b=256.^(0:N_BYTES_PER_AUX-1)';

for m=1:length(pAux)
    indi1=pAux(m):pAux(m)+92;
    if all(indi1<rawN)
        rawp=raw(indi1,:);
        %extract the raw data info from data package
        offset=((1:N_AUX)-1)*N_BYTES_PER_AUX +3;
        auxb(:,m) = sum(rawp(offset+(1:N_BYTES_PER_AUX)') .* pows256b)'; %this line of code will only work in newer versions of matlab, sorry!
    end
end

%% now decode the status packages

%assumes all potential status packages ARE status packages (less
%computationally expensive), and the status packages are not precious data!
statusdata=nan(length(pStatp));

for m=1:length(pStatp)
    indi1=pStatp(m):pStatp(m)+92;
    if all(indi1<rawN)
        rawp=raw(indi1);
        %extract the raw data info from data package
        statusdata(m) = sum(rawp(2:3) .*  256.^(0:1)');
    end
end


%% select which data channels we are actually interested in based on sd file


frequs=2*(ML(:,1)-1)+(3-ML(:,4));  %frequencies are fixed per source, so easy to calculate

for k=1:size(ML,1)
    data(k,:)=abs(datac(ML(k,2),:,frequs(k)));
end


%% now find the remainder bytes, that is, those that were unusued because they likely were part of an incomplete package

finalbyteused=max([pAux;maxdatapackpos;pStatp])+N_BYTES_TO_READ_PER_SAMPLE-1;
remainderbytes=raw(finalbyteused+1:end); %these bytesshould be appended to beggining of next stream


%% finally, prepare data output

dataoutput=[data;auxb];
dataoutput=dataoutput(:,~all(isnan(dataoutput))); %eliminate columns with no data

packlen=sum(~isnan(dataoutput),2);  %number of samples in data package