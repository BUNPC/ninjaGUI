%% read file
%fName='darkState.bin';
fName = 'ninjaNIRS2022_2023-05-05-19-59-32.bin';
fID=fopen(fName);
inputBytes=fread(fID,'uint8');
fclose(fID);

%% load SD file
% SD_file = 'C:\Users\ninjaNIRS\Documents\Software\ninjaGUI\autosave\probe_24x56\probe_frontalHD_24x56_reorderedv2.SD'
% load(SD_file,'-mat')
%%
stateMap = convertSDtoStateMap(SD);


%% use same stateMap used to acquire the file
% stateMap= zeros(1024,32);
% 
% if 0 % dark state calibration
%     stateMap(:,27) = 1;
% else % data collected
%     stateMap(1,[1 9]) = 1; % select LED
%     stateMap(1,19:21) = [1 0 0]; % power level mid
%     stateMap(3,[1 10]) = 1; % select LED
%     stateMap(3,19:21) = [1 0 0]; % power level mid
%     
%     stateMap(5,[3 9]) = 1; % select LED
%     stateMap(5,19:21) = [1 0 0]; % power level midf
%     stateMap(7,[3 10]) = 1; % select LED
%     stateMap(7,19:21) = [1 0 0]; % power level mid
%     
%     stateMap(9,[2 9]) = 1; % select LED
%     stateMap(9,19:21) = [1 0 0]; % power level mid
%     stateMap(11,[2 10]) = 1; % select LED
%     stateMap(11,19:21) = [1 0 0]; % power level mid
%     
%     stateMap(13,[4 9]) = 1; % select LED
%     stateMap(13,19:21) = [1 0 0]; % power level mid
%     stateMap(15,[4 10]) = 1; % select LED
%     stateMap(15,19:21) = [1 0 0]; % power level mid
%     
%     % dark state inbetween
%     stateMap(16:end,27) = 1; % mark sequence end
% end


%% translate with GUI function
[data,unusedBytes,darkLevelAvg,TGAdata]=translateNinja2022Bytes(inputBytes,stateMap,7);
data=circshift(data,-1,3);
%% variable data contains the translated information ordered as time by detectors by states

% example, plot detector 1 during state 3
foo=find(stateMap(:,27)==1);
nStates=foo(1);
fs=1000/nStates;
Ts=1/fs;

% t=0:Ts:Ts*(length(data)-1);
t=0:Ts:Ts*(size(data,1)-1);

plot(t,data(:,1,3))
xlabel('Time [s]')
ylabel('Intensity')
