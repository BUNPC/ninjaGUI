function LEDPowerCalibration( app )

stateMap_old = app.deviceInformation.stateMap;

hWait = waitbar(0,sprintf('Power Level 0'));

for iPower = 1:7

    waitbar(iPower/7,hWait,sprintf('Power Level %d',iPower));

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
    fnameDark=sprintf('LEDPowerCalibration_%02d.bin',iPower);
    fileID=fopen(fnameDark,'w');

    % backup normal fID
    standardfID=app.fstreamID;

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
    dataLEDPowerCalibration(:,:,iPower) = app.deviceFunctions.ReadBytesAvailable(app);
end
close(hWait)

disp('LED Power Calibration Data Acquisition Finished')

% if acquired successfully
% return state to default
%app.deviceFunctions.StateSetup(app,[]);

%if isfield(app.nSD,'freqMap')
%    app.deviceFunctions.StateSetup(app,app.nSD.freqMap);
%else
%    app.deviceFunctions.StateSetup(app,[]);
%end

%close file
fclose(fileID);

% return fID to default
app.fstreamID=standardfID;

% return the subtract dark flag to whatever it should be
if app.SubtractdarkMenu.Checked
    app.deviceInformation.subtractDark=1;
else
    app.deviceInformation.subtractDark=0;
end

% dual power cycling or not
if 0 % single power setting

    % STILL NEED TO UPDATE STATEMAP WITH OPTIMAL POWERS
    app.deviceInformation.stateMap = stateMap_old;
    app.deviceInformation.stateIndices =stateIndices_old;

else % dual power setting

    % Dual Power Cycling
    % optimize power levels and update stateMap and stateIndices
    app.deviceInformation.dataLEDPowerCalibration = dataLEDPowerCalibration;

    % need to create srcPowerLowHigh(nSrc,nDet,nWav)

    [stateMap, stateIndices, optPowerLevel] = LEDPowerCalibration_dualLevels(app.nSD,dataLEDPowerCalibration);
    app.deviceInformation.stateMap = stateMap;
    app.deviceInformation.stateIndices = stateIndices;
    app.deviceInformation.optPowerLevel = optPowerLevel;
    save('dualPowerStateMapandIndices.mat','stateMap','stateIndices','optPowerLevel')
    uploadToRAM(app.sp, stateMap, 'a', false);
end

% update rate
foo=find(stateMap(:,27)==1);

nStates=foo(1);
fs=800/nStates;
app.deviceInformation.Rate=fs;
app.editRate.Value=app.deviceInformation.Rate;
