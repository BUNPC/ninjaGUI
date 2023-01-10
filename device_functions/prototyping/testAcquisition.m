
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
N=40;
pause(N)

%% read bytes available
A=read(stat.s, stat.s.NumBytesAvailable, 'uint8');


%% stop acquisition 


stat.run = false;
stat = updateStatReg(stat);

% Q: what if I want to stop the device and turn it on again later? what is
% the sequence

%% close device
clear stat

%% translate bytestream to readable data
B=translateNinja2022Bytes(A);
fs=500;

t=(1:length(B))/fs;

figure(1)
semilogy(t,B(:,:,1))

figure(2)
semilogy(t,B(:,:,2))

figure(3)
semilogy(t,B(:,:,2)-B(:,:,1))