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

%% hardware constants
N_OPTODES=SD.nDets;
N_WORDS_PER_DFT = 2;
N_BYTES_IN_DFT_WORD = 5;
N_FREQ = 6;

N_BYTES_TO_READ_PER_SAMPLE=N_WORDS_PER_DFT * N_BYTES_IN_DFT_WORD * (N_FREQ+1) +5; % N_FREQ+1 : for max/avg data; +3 for [channel, #bytes, DFT count];

N_ACC_BYTES=14;
nAux=dev.nAux;

%% DFT constants and data offsets

DFT_N=1024;
KD = [21 24 28 30 32 35]; % demodulation k

offsetA = (0:N_FREQ-1)*N_BYTES_IN_DFT_WORD*N_WORDS_PER_DFT +3;
offsetB=offsetA+N_BYTES_IN_DFT_WORD;
wordpos=1:N_BYTES_IN_DFT_WORD;
[Foo1,Bar1]=meshgrid(wordpos,offsetA);
[Foo2,Bar2]=meshgrid(wordpos,offsetB);
part1=Foo1+Bar1;
part2=Foo2+Bar2;
part3=max(part2(:));
part4=part3 + N_BYTES_IN_DFT_WORD;
powso256=256.^(0:N_BYTES_IN_DFT_WORD-1);
Kernel=exp(-1i*(2*pi/DFT_N)*KD(1:N_FREQ));

%% read bytes available as a multiple of bytes in the buffer and number of optodes (and aux)

rb=s.NumBytesAvailable;

%triggers=[];

if rb>0
    raw = read(s,rb,'uint8')';
    if ~isempty(fID)
        fwrite(fID,raw,'uchar');
    end
else    
    maxvout=[];
    avgvout=[];
    data=[];
    packlen=0;
    datac=[];
    statusdata=[];
    remainderbytes=prevrbytes;         
    return;
end
statusdata=[];

raw=[prevrbytes;raw];
rawN=size(raw,1);


%% find indicator bytes
indicator=find(raw==N_BYTES_TO_READ_PER_SAMPLE-2);
indicator=indicator((indicator+N_BYTES_TO_READ_PER_SAMPLE-2)<=rawN); %only consider  potentially complete packages
packC=indicator-1;   %potential initial positions of data packets
packC(packC==0)=[];  %this means we missed the initial byte of one data packet

%% now, find candidate data packages by making sure the previous byte to the indicator corresponds to one of the optodes
pDatap=packC(raw(packC)>=0&raw(packC)<N_OPTODES); %possible detector positions

%% now look for the stop bytes; if they don't have them, then they are not data packages
%these are way more likely to be the actual positions of the data packages
pDatap=pDatap(raw(pDatap+N_BYTES_TO_READ_PER_SAMPLE-2,:)==170&raw(pDatap+N_BYTES_TO_READ_PER_SAMPLE-1,:)==170);

%% Find accelerometer packages
indicator=find(raw==N_ACC_BYTES-2); %the second byte of an accel/aux package is the number of bytes from there to the end
indicator=indicator((indicator+N_ACC_BYTES-2)<=rawN); %only consider  potentially complete packages
packC=indicator-1;   %potential initial positions of acc packages
packC(packC==0)=[];  %this means we missed the initial byte of one acc packet
pAccp=packC(raw(packC)==201); %has to be 201 for acc
pAccp=pAccp(raw(pAccp+N_ACC_BYTES-2,:)==170&raw(pAccp+N_ACC_BYTES-1,:)==170); %check that the stop bytes are there

%% Decode accelerometer packages

%identify auxiliary packets
seqk=raw(min(pAccp+2,end));  %contains the sequence data of potential data package; real data packages should be on a consecutive sequence
dseqk=diff(seqk);
sbreaks=find(dseqk~=1&dseqk~=-255); %sequence breaks
try
    if dseqk(1)==1
        sbreaks=sbreaks(2:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
    else
        %in the unlikely case the first packet was the sequence breaking one
        sbreaks=sbreaks(1:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
    end
catch
    disp('')
end
accind=pAccp;
accind(sbreaks)=[];  %remove the sequence breaking packages
maxaccpackpos=0;
maxaccpackpos=max(max(maxaccpackpos),max(accind));

% accelerometer decoding
if ~isempty(maxaccpackpos)
    try        
        acc=raw(pAccp-1+(4:2:10))*256+raw(pAccp-1+(5:2:11));
        if length(pAccp)==1
            acc=acc';
        end
    catch
        disp('bug 0')
    end
    acc(acc>(2^15-1))=acc(acc>(2^15-1))-2^16;
    try
        acc(:,1:3)=acc(:,1:3)/4* 0.488 /1000;
    catch ME
        disp(ME.meesage)
    end
    try
    acc(:,4)=acc(:,4)/256+25; %this is actually temperature
    catch ME
        disp(ME.meesage)
    end
    acc(:,5)=raw(pAccp-1+12);
    %triggers=raw(pAccp-1+12); %remote trigger byte; 0 means no trigger happened
else
    acc=[];
end
% triggers=[];
% if any(trigg)
%     %now do something if the trigger did happen
%     triggers=unique(trigg(~~trigg)); %find triggers that actually happened
%     triggtimes=;
% end

%% initialize databuffer
ML=SD.measList;

%maxsampN=ceil(1.5*length(pDatap)/N_OPTODES+3); %max number of samples possibly contained in the data package; actually modified it so it still works under some unforseen circumstances
maxsampN=ceil(length(pDatap)); %I modified the last line for an extreme case in which some optodes are not sending data; not sure if it's a good idea because it might create unnecessarily large data buffers
datac=complex(nan(N_OPTODES,maxsampN,N_FREQ)); %complex data buffer
data=nan(size(ML,1)+nAux,maxsampN); %buffer for intensity data

%% decode the optode data packets
databm=complex(nan(maxsampN,N_FREQ));
maxdatapackpos=0;
maxvout=nan(N_OPTODES,size(databm,1));
avgvout=nan(N_OPTODES,size(databm,1));
for k=0:N_OPTODES-1
    indik=pDatap(raw(pDatap)==k);  %contain the indices of the potential data packages on raw for optode k
    
    seqk=raw(min(indik+2,end));  %contains the sequence data of potential data package; real data packages should be on a consecutive sequence
    
    dseqk=diff(seqk);
    sbreaks=find(dseqk~=1&dseqk~=-255); %sequence breaks
    try
        if dseqk(1)==1
            sbreaks=sbreaks(2:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
        else
            %in the unlikely case the first packet was the sequence breaking one
            sbreaks=sbreaks(1:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
        end
    catch
        disp('')
    end
    
    dataindk=indik;
    dataindk(sbreaks)=[];  %remove the sequence breaking packages

    maxdatapackpos=max([maxdatapackpos;max(dataindk)]);
    
    %the previous code is also potentially losing the last data point, but
    %1) doing that prevents errors, 2) it also prevents errors in the
    %likely case that it was truncated
    
    
    %% now, for each element of dataindk...
    mLength=size(dataindk,1);
    databm=databm*nan;
    
    for m=1:mLength
        %% I need to convert the data package to intensity data
        try
            indi1=dataindk(m):(dataindk(m)+N_BYTES_TO_READ_PER_SAMPLE-1); %indices for package
        catch ME
            disp('Gathering error information')
            BytesAvail_When_error=s.NumBytesAvailable; %was there data in the buffer?
     
            pause(.05)
            BytesAvail_When_error_2=s.NumBytesAvailable; %is data still coming after error
            %write(app.sp,[1,255,197],"uint8");
            
            errorLog.BytesAvail_When_error=BytesAvail_When_error;
            errorLog.BytesAvail_When_error2=BytesAvail_When_error_2;
            errorLog.dataindk_causingerror=dataindk;
            errorLog.ME=ME;
            errorLog.raw=raw;
            errorLog.prevrbytes=prevrbytes;
            save(['error_ninjaGUI_',datestr(now,'yyyy-MM-dd-HH-mm-ss')],'errorLog')            
            
            %try to recover
            write(s,[1 255 198],"uint8"); %stop acquisition
            flush(s);  %flush buffer
            pause(0.5)  %pause 0.5 seconds
            write(s,[1 255 197],"uint8"); %restart acquisition                        
            data=[];
            packlen=0;
            datac=[];
            statusdata=[];
            remainderbytes=[];  %assume the bytes I read were bad and discard them
            return;
            
            %disp(ME)
            
        end
        
        if all(indi1<=rawN)  %this check is to avoid incomplete data packages
            rawp=raw(indi1,:);
            %transform raw data to complex FT
            pnm1=sum(rawp(part1).*powso256,2)';
            indi=pnm1>(2^39-1);
            pnm1(indi)=pnm1(indi)-2^40;
            pnm0=sum(rawp(part2).*powso256,2)';
            indi=pnm0>(2^39-1);
            pnm0(indi)=pnm0(indi)-2^40;
            %             datab(k+1,m,:)=pnm0 - Kernel.*pnm1;
            databm(m,:)=pnm0 - Kernel.*pnm1;
            try
                maxvout(k+1,m)=sum(rawp((1:N_BYTES_IN_DFT_WORD) + part3).* powso256');
                avgvout(k+1,m) = sum(rawp((1:N_BYTES_IN_DFT_WORD) + part4).* powso256')/DFT_N;             
            catch ME
                disp(ME.message)
            end
        end
    end
    %toc
    try
        datac(k+1,:,:)=databm;
    catch ME
        disp(ME.message)
    end
end
%% the following code determines which of the frequencies from which optode
% %% we are interested in, based on the experimental design on SD

% there is probably a way to vectorize this
frequs=zeros(size(ML,1),1);
for k=1:size(ML,1)
    frequs(k)=SD.freqMap(ML(k,1),ML(k,3),ML(k,4));
end

for k=1:size(ML,1)
    data(k,:)=abs(datac(ML(k,2),:,abs(frequs(k))));
end
%add aux channels
if nAux>0
    data(k+1:k+nAux,1:size(acc,1))=acc';
end

%% now find the remainder bytes, that is, those that were unusued because they likely were part of an incomplete package

finalbyteuseddata=max(maxdatapackpos)+N_BYTES_TO_READ_PER_SAMPLE-1;
finalbyteusedacc=max(maxaccpackpos)+N_ACC_BYTES-1;
finalbyteused=max([finalbyteusedacc,finalbyteuseddata]);
remainderbytes=raw(finalbyteused+1:end); %these bytesshould be appended to beggining of next stream


%% finally, prepare data output
avgvout=avgvout(:,~all(isnan(avgvout)));
maxvout=maxvout(:,~all(isnan(maxvout)));

dataoutput=data(:,~all(isnan(data))); %eliminate columns with no data
packlen=sum(~isnan(data),2);  %number of samples in data package per channel; the accelerometer channels will always have an equal number of samples, but I will still broadcast for each individual channel for simplicity
