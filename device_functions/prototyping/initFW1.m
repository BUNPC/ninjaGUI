%%
stat = initStat();

%%
uploadToRAM(stat.s, stat.rama, 'a', false);
uploadToRAM(stat.s, stat.ramb, 'b', false);
stat = powerOn(stat);

%%

% fw1 = serialport('COM9',115200);
% fw2 = serialport('COM10',115200);
