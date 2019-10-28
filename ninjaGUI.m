function ninjaGUI(fname)
%Routine to check initial configuration of the fNIRS device and launch the
%startup sequence
if nargin==0
    fname='fNIRS.cfg';
end


%set path to functions
addpath(genpath('device_functions'))

%% check existence of of cfg
disp(['Looking for ',fname,'...'])
if exist(fname,'file')
    disp(['Loading ',fname,'...'])    
    [devinfo,error]=loadCFG(fname);
    if error
        disp('fNIRS.cfg corrupt, starting configuration dialog')
        okflag=0;
    else
        okflag=1;
    end
else
    disp('fNIRS.cfg not found, starting configuration dialog')
    okflag=0;
end

if okflag
    %call set environment function with devinfo input
    disp(['Setting environment'])    
    environment=setEnv(devinfo);
    disp(['Starting NIRS application'])    
    %start main app with environment input
    fNIRSapp(devinfo,environment)
    %disp('Success')
else
    %start configuration dialog
    hardwareselect()
end