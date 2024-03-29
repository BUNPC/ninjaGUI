function LEDPowerCalibration( app, hAxes )

if ~exist('hAxes')
    reportSigLevel( app, 1 );
    return
end
flagSpatialMultiplex = get(hAxes.cb,'value');

stateMap_old = app.deviceInformation.stateMap;

%hWait = waitbar(0,sprintf('Power Level 0'));
set( hAxes.txa_pow,'value',sprintf('Reading Power Level 0 of 7...'));

% backup normal fID
standardfID=app.fstreamID;

fname=char(datetime('now','Format','y-MM-dd-HH-mm-ss'));

for iPower = 0:7

%    waitbar(iPower/7,hWait,sprintf('Power Level %d',iPower));
    set( hAxes.txa_pow,'value',sprintf('Reading Power Level %d of 7...',iPower));

    stateMap = createLEDPowerCalibrationStateMap( app.nSD, iPower );

    app.deviceInformation.stateMap = stateMap ;

    foo=find(stateMap(:,27)==1);
    nStates=foo(1);
    fs=800/nStates;

    %initialize both RAMs
%    stat=initStat(app,stateMap);


    %app.deviceInformation.Rate=fs;
    %app.editRate.Value=app.deviceInformation.Rate;

    stateIndices_old = app.deviceInformation.stateIndices;
    app.deviceInformation.stateIndices=mapToMeasurementList(app.deviceInformation.stateMap,app.nSD.measList);

    %app.deviceInformation.subtractDark = 1;

    %%
    % save stat in the app variable

    %submit to device
    uploadToRAM(app.sp, stateMap, 'a', false);
%    uploadToRAM(app.sp, stat.ramb, 'b', false);

    %stat = powerOn(app.sp,stat);

    %app.deviceInformation.stat=stat;

    % make sure the incoming acquisition won't subtract dark from
    % dark
    app.deviceInformation.subtractDark=0;

    % create and open file
    foldname=char(datetime('now','Format','y-MM-dd'));
    foldname2 = 'LEDPowerCalibration';
    %create autosave directory
    %                 if ~exist(['autosave',filesep,foldname],'dir')
    %                     mkdir(['autosave',filesep,foldname])
    %                 end
    % Below if updated by SK to create saving folder with
    % datestamp in probe dircetory instead of autoSave
    % directory
    if ~exist(['.\' foldname],'dir')
        mkdir([foldname])
    end
    if ~exist(['.\' foldname '\' foldname2],'dir')
        mkdir([foldname '\' foldname2])
    end

    fnameDark=sprintf('%s\\%s\\LEDPowerCalibration_%02d_%s.bin',foldname,foldname2,iPower,fname);
    fileID=fopen(fnameDark,'w');

    %switch it by dark fID
    app.fstreamID=fileID;

    % turn acquisition on
    app.deviceFunctions.Acquisition(app,'start');

    % wait N seconds

    pause(1)

    %stop acquisition
    app.deviceFunctions.Acquisition(app,'stop');

    % call BytesAvailable function; this will save dark to bin
    % file, but will also return dark
%    dataDark(:,iPower) = mean(app.deviceFunctions.ReadBytesAvailable(app),2,'omitnan');
    [data,~,~,~,~,~,~,dataDarkTmp,B] = app.deviceFunctions.ReadBytesAvailable(app);
    if iPower>0
        dataLEDPowerCalibration(:,iPower) = squeeze(mean(data,2,'omitnan'));
        Bpow(:,:,iPower) = squeeze( mean(B,1,'omitnan') );
    else
        dataDark = mean(dataDarkTmp,2,'omitnan'); % really only need the lowest power level
        B_Dark = B;
        Bpow = zeros(size(B,2),size(B,3),7);
    end

    %close file
    fclose(fileID);
    
end
set( hAxes.txa_pow,'value',sprintf('Plotting Results...'));
%close(hWait)

disp('LED Power Calibration Data Acquisition Finished')

% if acquired successfully
% return state to default
%app.deviceFunctions.StateSetup(app,[]);

%if isfield(app.nSD,'freqMap')
%    app.deviceFunctions.StateSetup(app,app.nSD.freqMap);
%else
%    app.deviceFunctions.StateSetup(app,[]);
%end

% return fID to default
app.fstreamID=standardfID;

% return the subtract dark flag to whatever it should be
if app.SubtractdarkMenu.Checked
    app.deviceInformation.subtractDark=1;
else
    app.deviceInformation.subtractDark=0;
end

% dual power cycling or not
thresholds = app.deviceInformation.levelRepresentation.thresholds;
if 0 % single power setting

    % STILL NEED TO UPDATE STATEMAP WITH OPTIMAL POWERS
    app.deviceInformation.stateMap = stateMap_old;
    app.deviceInformation.stateIndices =stateIndices_old;

else % dual power setting

    % Dual Power Cycling
    % optimize power levels and update stateMap and stateIndices
    app.deviceInformation.dataLEDPowerCalibration = dataLEDPowerCalibration;

    % need to create srcPowerLowHigh(nSrc,nDet,nWav)

    [stateMap, stateIndices, optPowerLevel, dSig, srcModuleGroups] = LEDPowerCalibration_dualLevels(app.nSD,dataLEDPowerCalibration,thresholds,flagSpatialMultiplex);
    app.deviceInformation.stateMap = stateMap;
    app.deviceInformation.stateIndices = stateIndices;
    app.deviceInformation.optPowerLevel = optPowerLevel;
    app.deviceInformation.dSig = dSig;
    app.deviceInformation.srcModuleGroups = srcModuleGroups;
    app.deviceInformation.flagSpatialMultiplex = flagSpatialMultiplex;
    nSD = app.nSD;
    save('dualPowerStateMapandIndices.mat','stateMap','stateIndices','optPowerLevel','dSig','Bpow','nSD','thresholds')
    uploadToRAM(app.sp, stateMap, 'a', false);
end

% update rate
foo=find(stateMap(:,27)==1);

nStates=foo(1);
fs=app.deviceInformation.stat.state_fs / nStates; 
app.deviceInformation.Rate=fs;
app.editRate.Value=app.deviceInformation.Rate;

%%
% report
reportSigDark( app.nSD, dSig, dataDark, B_Dark, thresholds, hAxes );
set( hAxes.txa_pow,'value',sprintf(''));
