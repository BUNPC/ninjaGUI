function result = StateSetup(app,stateMap)
%StateSetupS The purpose of this function is to setup the state of the
%sources, detectors for the acquisition. Can be used to setup the
%frequencies of the LEDs, or the power levels if they are fixed, or the
%state sequences if there is temporal multiplexion


%hard code the states for now; I will have to find a convenient and
%compatible way to do 

stateMap= zeros(1024,32);

stateMap(1,[1 9]) = 1; % select LED
stateMap(1,19:21) = [0 1 0]; % power level mid
stateMap(3,[1 10]) = 1; % select LED
stateMap(3,19:21) = [0 1 0]; % power level mid

stateMap(5,[3 9]) = 1; % select LED
stateMap(5,19:21) = [0 1 0]; % power level mid
stateMap(7,[3 10]) = 1; % select LED
stateMap(7,19:21) = [0 1 0]; % power level mid

% dark state inbetween
stateMap(8:end,27) = 1; % mark sequence end

%initialize both RAMs

stat=initStat(stateMap);

% save stat in the app variable

%submit to device
uploadToRAM(app.sp, stat.rama, 'a', false);
uploadToRAM(app.sp, stat.ramb, 'b', false);

stat = powerOn(stat);

app.deviceInformation.stat=stat;

result=1;
end

