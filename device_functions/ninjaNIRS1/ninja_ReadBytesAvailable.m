function [data,packlen,remainderbytes,datac,statusdata]=ninja_ReadBytesAvailable(s,dev,SD,prevrbytes,fID)
% Reads the serial port for a ninjaNIRS device. It reads N_Optodes
% sequentially. That means that if data is out of order data will be lost
% (for example, is the data arrive to the buffer in the order 12314234, the
% first data output will contain data for optode 2,3 correctly, a NaN for
% 4, and the data for 1 will be for a sampling instant ahead; then the next
% one will have NaN at 1, and the correct data for 2, 3, 4. This means
% three samples were lost and one is in the incorrect location, but the
% logic is simple and avoids further desync (as long as data gets there in
% order). The function should probably be more robust to avoid those issues
% (though that would make it slower).



%% hardware constants
N_OPTODES=SD.nDets;
N_WORDS_PER_DFT = 2;
N_BYTES_IN_DFT_WORD = 5;
N_FREQ = 6;

N_BYTES_TO_READ_PER_SAMPLE=N_WORDS_PER_DFT * N_BYTES_IN_DFT_WORD * (N_FREQ+1) +5; % N_FREQ+1 : for max/avg data; +3 for [channel, #bytes, DFT count];




%% DFT constants and data offsets

DFT_N=128;
KD = [18 20 21 24 28 30 32 35]; % demodulation k

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

ba=s.BytesAvailable;

%this code helps prevent reading incomplete data packages
npacks=20;   %making this constant larger means we read more packets at a time, reducing processing overhead, but making it too large will affect refresh rate
rb=floor(ba/N_BYTES_TO_READ_PER_SAMPLE/N_OPTODES/npacks)*N_BYTES_TO_READ_PER_SAMPLE*N_OPTODES*npacks;

if rb>0
    raw = fread(s,rb,'uchar');
    %fwrite(fID,raw,'uchar');
else
    data=[];
    packlen=0;
    datac=[];
    statusdata=[];
    remainderbytes=[];
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
%stop bytes not implemented yet (??)
pDatap=pDatap(raw(pDatap+N_BYTES_TO_READ_PER_SAMPLE-2,:)==170&raw(pDatap+N_BYTES_TO_READ_PER_SAMPLE-1,:)==170);



%% initialize databuffer
ML=SD.measList;

maxsampN=ceil(1.5*length(pDatap)/N_OPTODES+3); %max number of samples possibly contained in the data package; actually modified it so it still works under some unforseen circumstances
datac=complex(nan(N_OPTODES,maxsampN,N_FREQ)); %complex data buffer
data=nan(size(ML,1),maxsampN); %buffer for intensity data


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
            %             datab(k+1,m,:)=pnm0 - Kernel.*pnm1;
            databm(m,:)=pnm0 - Kernel.*pnm1;
        end
    end
    try
    datac(k+1,:,:)=databm;
    catch
        disp('bug')
    end
end

%% the following code determines which of the frequencies from which optode
% %% we are interested in, based on the experimental design on SD 

%I need to use the frequency map to see which rows and columns I actually
%want

% % % ind = sub2ind(size(SD.freqMap),ML(:,1),ML(:,3),ML(:,4));
% % % fMap=SD.freqMap;
% % % fss=abs(fMap(ind));
% % % dets=ML(:,2);
% % % ind2 = sub2ind(size(datac),dets,ones(size(dets)),fss);
% % % data=abs(datac(ind2));

% there is probably a way to vectorize this
frequs=zeros(size(ML,1),1);
for k=1:size(ML,1)
    frequs(k)=SD.freqMap(ML(k,1),ML(k,3),ML(k,4));
end

for k=1:size(ML,1)
    data(k,:)=abs(datac(ML(k,2),:,abs(frequs(k))));
end


%% now find the remainder bytes, that is, those that were unusued because they likely were part of an incomplete package

finalbyteused=max(maxdatapackpos)+N_BYTES_TO_READ_PER_SAMPLE-1;
remainderbytes=raw(finalbyteused+1:end); %these bytesshould be appended to beggining of next stream

%% finally, prepare data output

data=data(:,~all(isnan(data))); %eliminate columns with no data
packlen=sum(~isnan(data),2);  %number of samples in data package per channel
