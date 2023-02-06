%% read file
fName='ninjaNIRS20222023-01-31-10-32-32.bin';
fID=fopen(fName);
inputBytes=fread(fID,'uint8');
fclose(fID);


%% use same stateMap used to acquire the file
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


%% translate with GUI function
[data,unusedBytes]=translateNinja2022Bytes(inputBytes,stateMap,1);
data=circshift(data,-1,3);
%% variable data contains the translated information ordered as time by detectors by states

% example, plot detector 1 during state 3
foo=find(stateMap(:,27)==1);
nStates=foo(1);
fs=1000/nStates;
Ts=1/fs;

t=0:Ts:Ts*(length(data)-1);

plot(t,data(:,1,3))
xlabel('Time [s]')
ylabel('Intensity')