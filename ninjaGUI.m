function ninjaGUI(fname)
%This script launches ninjaNIRS based according to the specifications in
%the hardware configuration (cfg) and the probe files

specFolderName='device_functions';
comSpecfName='communicationSpecs.txt';

%parse compatibility from device specification folders
disp('Checking compatible devices...')
compatDevices=checkCompatibility();

if isempty(compatDevices)
    disp('Found no compatible devices, verify your ninjaGUI install')
    return
end
disp('This install is compatible with the following devices:')
for ki=1:length(compatDevices)
    disp(compatDevices{ki})
end

%select config file for current device
if nargin==0
    [fname,path]=uigetfile({'*.cfg', 'Hardware configuration file (*.cfg)'});
    fname=fullfile(path,fname);
    if ~fname
        disp('No file selected, defaulting to fNIRS.cfg')
        fname='fNIRS.cfg';
    end
elseif length(fname)<4
    fname = strcat(fname,'.cfg');
elseif ~strcmp(fname(end-3:end),'.cfg')
    fname = strcat(fname,'.cfg');
end

%set path to functions
addpath(genpath(specFolderName))

%% check existence of of cfg
disp(['Looking for ',fname,'...'])
if exist(fname,'file')
    disp(['Loading ',fname,'...'])    
    [devinfo,error]=loadCFG(fname);
    if error
        disp([filename, ' corrupt, starting configuration dialog'])
        okflag=0;
    else
        okflag=1;
    end
else
    disp([fname ' not found, starting configuration dialog'])
    okflag=0;
end

devinfo.specFolder=specFolderName;
devinfo.comSpecFile=comSpecfName;

%verify that config file corresponds with a compatible device
%first, handle special cases of inconsistent device name conventions;
%hopefully this will be cleaned up in the future/more consistent names will
%be used
switch devinfo.devID
    case 'ninjaNIRS'
        devinfo.devID='ninjaNIRS2020';
    case 'fNIRS1k'
        devinfo.devID='NIRS1k';
end
%now, make sure the devID is in the compatible list
if ~any(ismember(compatDevices,devinfo.devID))
    disp('This device configuration is not compatible with the current install of ninjaGUI. Make sure the device specifications are correctly installed or that the config file corresponds with your device')
    return
end

if okflag
    %call set environment function with devinfo input
    disp(['Setting GUI environment for device ',devinfo.devID])    
    environment=setEnv(devinfo);
    disp('Starting ninjaGUI application')    
    %start main app with environment input
    fNIRSapp(devinfo,environment)
    %disp('Success')
else
    %start configuration dialog
    hardwareselect()
end