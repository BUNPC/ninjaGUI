function ninjaGUI(fname)
%Routine to check initial configuration of the fNIRS device and launch the
%startup sequence
if nargin==0
    [fname,path]=uigetfile({'*.cfg', 'Hardware configuration file (*.cfg)'});
    fname=[path,filesep,fname];
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
addpath(genpath('device_functions'))

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

if okflag
    %call set environment function with devinfo input
    disp('Setting environment')    
    environment=setEnv(devinfo);
    disp('Starting NIRS application')    
    %start main app with environment input
    fNIRSapp(devinfo,environment)
    %disp('Success')
else
    %start configuration dialog
    hardwareselect()
end