
N=10; %number of seconds to acquire

%% connect to device
stat = initStat();

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
[B,unusedBytes]=translateNinja2022Bytes(A);
Nstates=size(B,3);
fs=1e3/Nstates;


%% plot
plotN=ceil(sqrt(Nstates));

t=(1:length(B))/fs-1;

tiledlayout(plotN,plotN);

limites=[1,1.1*max(B(:))];

for ki=1:Nstates
    nexttile
    semilogy(t,B(:,:,ki))
    ylim(limites)
    xlim([0,max(t)])
    title(num2str(ki-1))
end

%% close device
clear stat
