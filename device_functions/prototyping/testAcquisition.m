
N=50; %number of seconds to acquire

%% connect to device
stat = initStat1(150e-6);

%% upload state definitions and power on; NOTE: MAKE SURE YOU UNDERSTAND THE POWER ON AND POWER OFF SEQUENCE AND HOW IT RELATES TO CREATING/CONNECTING THE DEVICE
uploadToRAM(stat.s, stat.rama, 'a', false);
uploadToRAM(stat.s, stat.ramb, 'b', false);
stat = powerOn(stat);

%% Reset program counters (probably just equivalent to a flush buffer operation)

stat=ResetCounters(stat);

%% start acquisition
disp('starting acquisition')
stat=StartAcquisition(stat);


%% acquire for N seconds

pause(N)

%% read bytes available
A=read(stat.s, stat.s.NumBytesAvailable, 'uint8');

%% stop acquisition 


stat.run = false;
stat = updateStatReg(stat);

% Q: what if I want to stop the device and turn it on again later? what is
% the sequence


%% translate bytestream to readable data
stateMap=stat.rama;
[B,unusedBytes]=translateNinja2022Bytes(A',stateMap,2);
Nstates=size(B,3);
fs=1e3/Nstates;


%% plot

figure(1)
plotN=ceil(sqrt(Nstates));

t=((1:length(B))-1)/fs;

tiledlayout(plotN,plotN);

limites=[1,1.1*max(B(:))];

for ki=1:Nstates-1
    nexttile
    semilogy(t,B(:,:,ki)-B(:,:,ki+1))
    ylim(limites)
    xlim([0,max(t)])
    title(num2str(ki-1))
end

%%
% figure(2)
% semilogy(t,B(:,2,2))

%% close device
clear stat
