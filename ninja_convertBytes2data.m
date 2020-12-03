function [data,packlen,remainderbytes,triggers,datac,statusdata]=ninja_convertBytes2data(raw,nAux,nOptodes,prevrbytes)
% Converts a raw bytestream captured with ninjaNIRS to its equivalent DFT
% coefficients. datac is the output converted complex data. packlen is how
% many samples were read per optode, remainderbytes are the unused bytes on
% the stream due to incomplete captured packages, triggers are the remote
% triggers if there was any. data is the magnitude of the complex data.
% statusdata is unused right now. The inputs are raw, the raw bytestream.
% nAux, the number of auxiliaries being sampled, nOptodes in theory is the
% number of optodes in the system, but in practice is the largest optode ID
% present in the system (for example, if there are only 5 optodes connected
% to ninjaNIRS, but they are in ports 2, 4, 7, 15, 19, we should use 19 as
% nOptodes); of course, in general we should connect them to consecutive
% ports starting from the first one. prevrbytes contains remainder bytes of
% a previous acquisition to the current, if there was such a thing and it
% had unused bytes (that way, the data packets will be completed)

if isrow(raw)
    raw=raw';
end


%% hardware constants
N_OPTODES=nOptodes;
N_WORDS_PER_DFT = 2;
N_BYTES_IN_DFT_WORD = 5;
N_FREQ = 6;

N_BYTES_TO_READ_PER_SAMPLE=N_WORDS_PER_DFT * N_BYTES_IN_DFT_WORD * (N_FREQ+1) +5; % N_FREQ+1 : for max/avg data; +3 for [channel, #bytes, DFT count];

N_ACC_BYTES=14;
%nAux=4;

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
powso256=256.^(0:N_BYTES_IN_DFT_WORD-1);
Kernel=exp(-1i*(2*pi/DFT_N)*KD(1:N_FREQ));

%% read bytes available as a multiple of bytes in the buffer and number of optodes (and aux)

ba=length(raw);

%this code helps prevent reading incomplete data packages
npacks=20;   %making this constant larger means we read more packets at a time, reducing processing overhead, but making it too large will affect refresh rate
rb=floor(ba/N_BYTES_TO_READ_PER_SAMPLE/N_OPTODES/npacks)*N_BYTES_TO_READ_PER_SAMPLE*N_OPTODES*npacks;

triggers=[];

if rb<=0   
    data=[];
    packlen=0;
    datac=[];
    statusdata=[];
    remainderbytes=[];
    return;
end
statusdata=[];

raw=[prevrbytes;raw];
rawN=length(raw);


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
    catch
        disp('bug 0')
    end
    acc(acc>(2^15-1))=acc(acc>(2^15-1))-2^16;
    acc(:,1:3)=acc(:,1:3)/4* 0.488 /1000;
    acc(:,4)=acc(:,4)/256+25; %this is actually temperature
    
    triggers=raw(pAccp-1+12); %remote trigger byte; 0 means no trigger happened
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
%ML=SD.measList;

%maxsampN=ceil(1.5*length(pDatap)/N_OPTODES+3); %max number of samples possibly contained in the data package; actually modified it so it still works under some unforseen circumstances
maxsampN=ceil(length(pDatap)); %I modified the last line for an extreme case in which some optodes are not sending data; not sure if it's a good idea because it might create unnecessarily large data buffers
datac=complex(nan(N_OPTODES,maxsampN,N_FREQ)); %complex data buffer




%% decode the optode data packets
databm=complex(nan(maxsampN,N_FREQ));
maxdatapackpos=0;
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
    
    maxdatapackpos=max(max(maxdatapackpos),max(dataindk));
    
    %the previous code is also potentially losing the last data point, but
    %1) doing that prevents errors, 2) it also prevents errors in the
    %likely case that it was truncated
    
    
    %% now, for each element of dataindk...
    mLength=length(dataindk);
    databm=databm*nan;
    
    for m=1:mLength
        %% I need to convert the data package to intensity data
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
            %             datab(k+1,m,:)=pnm0 - Kernel.*pnm1;
            databm(m,:)=pnm0 - Kernel.*pnm1;
        end
    end
    %toc
    try
        datac(k+1,:,:)=databm;
    catch
        disp('bug 1')
    end
end


%% now find the remainder bytes, that is, those that were unusued because they likely were part of an incomplete package

finalbyteuseddata=max(maxdatapackpos)+N_BYTES_TO_READ_PER_SAMPLE-1;
finalbyteusedacc=max(maxaccpackpos)+N_ACC_BYTES-1;
finalbyteused=max(finalbyteusedacc,finalbyteuseddata);
remainderbytes=raw(finalbyteused+1:end); %these bytesshould be appended to beggining of next stream

%% find how many samples were found per channel
packlen=zeros(1,nOptodes);
for ki=1:nOptodes
    tempo=squeeze(datac(ki,:,:));
    packlen(1,ki)=sum(~all(isnan(tempo')));
end
maxpacklen=max(packlen);


%% finally, prepare data output
%in datac, dim1 is channels, dim 2 is time/samples, dim 3 is frequency
%keep only the buffer elements with actual samples (remove placeholder
%nans)
datac=datac(:,1:maxpacklen,:);
data=abs(datac);
