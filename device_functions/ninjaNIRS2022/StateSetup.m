function result = StateSetup(app,stateMap)
%StateSetupS The purpose of this function is to setup the state of the
%sources, detectors for the acquisition. Can be used to setup the
%frequencies of the LEDs, or the power levels if they are fixed, or the
%state sequences if there is temporal multiplexion


%hard code the states for now; I will have to find a convenient and
%compatible way to do 

%2/7/23 update; currently the app will send an empty map, unless there is a
%stored map in the SD file somehow. Still hard coded here; I would
%recommend that somehow the state map for a given experiment is stored in
%the SD file for the experiment

stateMap= zeros(1024,32);

stateMap(1,[1 9]) = 1; % select LED
stateMap(1,19:21) = [1 0 0]; % power level mid
stateMap(3,[1 10]) = 1; % select LED
stateMap(3,19:21) = [1 0 0]; % power level mid

stateMap(5,[3 9]) = 1; % select LED
stateMap(5,19:21) = [1 0 0]; % power level mid
stateMap(7,[3 10]) = 1; % select LED
stateMap(7,19:21) = [1 0 0]; % power level mid

stateMap(9,[2 9]) = 1; % select LED
stateMap(9,19:21) = [1 0 0]; % power level mid
stateMap(11,[2 10]) = 1; % select LED
stateMap(11,19:21) = [1 0 0]; % power level mid

stateMap(13,[4 9]) = 1; % select LED
stateMap(13,19:21) = [1 0 0]; % power level mid
stateMap(15,[4 10]) = 1; % select LED
stateMap(15,19:21) = [1 0 0]; % power level mid

% dark state inbetween
stateMap(16:end,27) = 1; % mark sequence end

foo=find(stateMap(:,27)==1);

nStates=foo(1);
fs=1000/nStates;
%initialize both RAMs

stat=initStat(stateMap);

%% Add the state map to the GUI variables for latter use

% for now I will save the statemap as a field of deviceInformation (other fields are the cfg file)
app.nSD.freqMap=stateMap;
app.deviceInformation.stateMap=stateMap;
app.deviceInformation.Rate=fs;
app.editRate.Value=app.deviceInformation.Rate;

app.deviceInformation.stateIndices=mapToMeasurementList(app.deviceInformation.stateMap,app.nSD.measList);


%%
% save stat in the app variable

%submit to device
uploadToRAM(app.sp, stat.rama, 'a', false);
uploadToRAM(app.sp, stat.ramb, 'b', false);

stat = powerOn(app.sp,stat);

app.deviceInformation.stat=stat;

result=1;
end

