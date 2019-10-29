function [data,datab]=ninja_ReadBytesAvailable(s,dev,SD)
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
N_OPTODES=dev.nDets;
N_WORDS_PER_DFT = 2;
N_BYTES_IN_DFT_WORD = 5;
N_FREQ = 6;

N_BYTES_TO_READ_PER_SAMPLE=N_WORDS_PER_DFT * N_BYTES_IN_DFT_WORD * (N_FREQ+1) +3; % N_FREQ+1 : for max/avg data; +3 for [channel, #bytes, DFT count];




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

%% initialize databuffer
ML=SD.measList;

datab=complex(nan(N_OPTODES, 1, N_FREQ)); %buffer for all acquired data

data=nan(size(ML,1),1);

for k1=1:N_OPTODES
try
    [raw, count] = fread(s,N_BYTES_TO_READ_PER_SAMPLE,'uchar');
catch
    disp('Timeout')
    return
end


%error handling
if count < N_BYTES_TO_READ_PER_SAMPLE
    disp(['Error receiving data. cnt = ', num2str(count)]);
    return;
end
if ~(raw(1) < N_OPTODES)
    disp(['Source identifier error. Expecting 0 or 1, received ' num2str(raw(1))]);
    return;
end
iopt = raw(1)+1;

%                        disp(num2str(iopt))

if raw(2) ~= N_BYTES_TO_READ_PER_SAMPLE-2
    disp(['Byte number annunciation error. Expecting ' num2str(N_BYTES_TO_READ_PER_SAMPLE-2) ', received ' num2str(raw(2))]);
    return
end

% if raw(3) ~= mod(smpcnt(iopt),256)
%     disp(['Sample counter error. Expecting ' num2str(mod(smpcnt(iopt),256)) ', received ' num2str(raw(3))]);
%     return;
% end


%% transform raw data to intensity
pnm1=sum(raw(part1).*powso256,2)';
indi=pnm1>(2^39-1);
pnm1(indi)=pnm1(indi)-2^40;
pnm0=sum(raw(part2).*powso256,2)';
indi=pnm0>(2^39-1);
pnm0(indi)=pnm0(indi)-2^40;

%A(iopt,smpcnt(iopt)+1,1:N_FREQ) = pnm0 - Kernel.*pnm1;
datab(iopt,1,1:N_FREQ) = pnm0 - Kernel.*pnm1;

end

% the following code determines which of the frequencies from which optode
% we are interested in, based on the experimental design on SD 
ind = sub2ind(size(SD.freqMap),ML(:,1),ML(:,3),ML(:,4));
fMap=SD.freqMap;
fss=abs(fMap(ind));
dets=ML(:,2);
ind2 = sub2ind(size(datab),dets,ones(size(dets)),fss);
data=abs(datab(ind2));
