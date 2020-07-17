function [dataoutput,packlen,datab,statusdata]=fNIRS1k_ReadBytesAvailable2(s,dev,SD)
% Reads the serial port for a fNIRS1000 device. 

%% hardware constants
N_OPTODES=dev.nDets;
N_WORDS_PER_DFT = 2;
N_BYTES_IN_DFT_WORD = 5;
N_FREQ = 8;
N_AUX = dev.nAux;
N_BYTES_PER_AUX = 2;

N_BYTES_TO_READ_PER_SAMPLE=N_WORDS_PER_DFT * N_BYTES_IN_DFT_WORD * (N_FREQ+1) +3; % N_FREQ+1 : for max/avg data; +3 for [channel, #bytes, DFT count];




%% DFT constants and data offsets

DFT_N=512;
KD = [56 60 64 70 80 84 96 105]; % demodulation k

offsetA = (0:N_FREQ-1)*N_BYTES_IN_DFT_WORD*N_WORDS_PER_DFT +3;
offsetB=offsetA+N_BYTES_IN_DFT_WORD;
wordpos=1:N_BYTES_IN_DFT_WORD;
part1=wordpos+offsetA';
part2=wordpos+offsetB';
powso256=256.^(0:N_BYTES_IN_DFT_WORD-1);
Kernel=exp(-1i*(2*pi/DFT_N)*KD(1:N_FREQ));

%% read ALL bytes available

ba=s.BytesAvailable;
rb=floor(ba/N_BYTES_TO_READ_PER_SAMPLE)*N_BYTES_TO_READ_PER_SAMPLE;
raw = fread(s,rb,'uchar');


%% initialize databuffer
ML=SD.measList;

rawN=length(raw);
maxsampN=1+ceil(rawN/(N_OPTODES+1)/N_BYTES_TO_READ_PER_SAMPLE); %max number of samples possibly contained in the data package
datab=complex(nan(N_OPTODES,maxsampN,N_FREQ)); %complex data buffer
auxb=nan(N_AUX,maxsampN);  %aux data buffer

data=nan(size(ML,1),maxsampN); %buffer for intensity data




%% parse the data package

nBs=find(raw==N_BYTES_TO_READ_PER_SAMPLE-2); %find all possible indicators of the correct number of bytes read
nBs(nBs<2)=[];  %discard possible data packages in which I did not get the first byte
Optind=nBs(raw(nBs-1)<N_OPTODES)-1; %indices of potential optode data packages on raw, offset to get sequence indices
Auxind=nBs(raw(nBs-1)==200 )-1; %indices of potential auxiliary data packages
Statind=nBs(raw(nBs-1)==254)-1; %indices of potential status data packages




%% decode the optode data packets
for k=0:N_OPTODES-1
    indik=Optind(raw(Optind)==k);  %contain the indices of the potential data packages on raw for optode k

    seqk=raw(min(indik+2,rawN));  %contains the sequence data of potential data package; real data packages should be on a consecutive sequence
    
    
    dataindk=indik([diff(seqk)==1]);  %indices on raw for the data points that are actually in sequence and are most likely data points, BUT there is lost data, one at each jump
    %the previous code is also potentially losing the last data point, but
    %1) doing that prevents errors, 2) it also prevents errors in the
    %likely case that it was truncated
    
    
    %% now, for each element of dataindk...
    
    for m=1:size(dataindk,1)
        %% I need to actually convert the data package to intensity data
        indi1=dataindk(m):dataindk(m)+92;
        if all(indi1<rawN)
            rawp=raw(indi1);
            %transform raw data to intensity
            pnm1=sum(rawp(part1).*powso256,2)';
            indi=pnm1>(2^39-1);
            pnm1(indi)=pnm1(indi)-2^40;
            pnm0=sum(rawp(part2).*powso256,2)';
            indi=pnm0>(2^39-1);
            pnm0(indi)=pnm0(indi)-2^40;
            datab(k+1,m,:)=pnm0 - Kernel.*pnm1;
        end
    end
end

%% now decode the aux data packets

%discard incomplete aux packets
Auxind(Auxind+2>rawN)=[];


seqAux=raw(Auxind+2);  %contains the sequence data of potential aux packets

try 
Auxdataindk=Auxind([diff(seqAux)==1]);  %again, will lose data at each jump :(, and the last one of the data package
catch
    disp('This is a bug!')
end
pows256b=256.^(0:N_BYTES_PER_AUX-1)';

for m=1:length(Auxdataindk)
    indi1=Auxdataindk(m):Auxdataindk(m)+92;
    if all(indi1<rawN)
        rawp=raw(indi1);
        %extract the raw data info from data package
        offset=((1:N_AUX)-1)*N_BYTES_PER_AUX +3;        
        auxb(:,m) = sum(rawp(offset+(1:N_BYTES_PER_AUX)') .* pows256b)'; %this line of code will only work in newer versions of matlab, sorry!    
    end    
end

%% now decode the status packages

%assumes all potential status packages ARE status packages (less
%computationally expensive), and the status packages are not precious data!
statusdata=nan(length(Statind));

for m=1:length(Statind)
    indi1=Statind(m):Statind(m)+92;
    if all(indi1<rawN)
        rawp=raw(indi1);
        %extract the raw data info from data package
        statusdata(m) = sum(rawp(2:3) .*  256.^(0:1)');        
    end    
end


%% select which data channels we are actually interested in based on sd file


frequs=2*(ML(:,1)-1)+(3-ML(:,4));  %frequencies are fixed per source, so easy to calculate

for k=1:size(ML,1)
        data(k,:)=abs(datab(ML(k,2),:,frequs(k)));       
end

%% finally, prepare data output

dataoutput=[data;auxb];
dataoutput=dataoutput(:,~all(isnan(dataoutput))); %eliminate columns with no data

packlen=size(dataoutput,2); %number of samples in data package
