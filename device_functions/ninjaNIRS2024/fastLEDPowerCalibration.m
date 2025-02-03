function fastLEDPowerCalibration( app, hAxes )

stat = app.deviceInformation.stat; % DOES THIS WORK HERE? I need stat.s for initStat()

if ~exist('hAxes')
    reportSigLevel( app, 1 );
    return
end
flagSpatialMultiplex = get(hAxes.cb,'value');

% Get measList and Add rhoSDS to 5th column
measList = app.nSD.measList;
rhoSDS = zeros(size(measList,1),1);
for iML = 1:size(measList,1)
    iS = measList(iML,1);
    iD = measList(iML,2);
    rhoSDS(iML) = sum( (app.nSD.SrcPos3D(iS,:)-app.nSD.DetPos3D(iD,:)).^2 )^0.5;
end
measList(:,5) = rhoSDS;

set( hAxes.txa_pow,'value',sprintf('doing power calibration...'));

% Collect dark state
srcram = createLEDPowerCalibrationSrcRAM( app.nSD, 0 );
app.deviceInformation.srcram = srcram ;
foo=find(srcram(1,:,32)==1);
nStates=foo(1);
app.deviceInformation.stateIndices = mapToMeasurementList(app.deviceInformation.srcram,measList);
%submit to device
rama = zeros(1024,32);
rama(nStates:end,9) = 1; % mark sequence end

% backup normal fID
standardfID=app.fstreamID;
uploadToRAM( stat, rama, 'a', false);
for isrcb = 1:7
    if stat.srcb_active(isrcb)
        uploadToRAM(stat, squeeze(srcram(isrcb,:,:)), 'src', false, isrcb);
    end
end
fname=char(datetime('now','Format','y-MM-dd-HH-mm-ss'));
foldname=char(datetime('now','Format','y-MM-dd'));
foldname2 = 'LEDPowerCalibration';
if ~exist(['.\' foldname],'dir')
    mkdir([foldname])
end
if ~exist(['.\' foldname '\' foldname2],'dir')
    mkdir([foldname '\' foldname2])
end

fnameDark=sprintf('%s\\%s\\LEDPowerCalibration_a00_%s.bin',foldname,foldname2,fname);
fileID=fopen(fnameDark,'w');
app.fstreamID=fileID;

% turn acquisition on
app.deviceFunctions.Acquisition(app,'start');
pause(1)
%stop acquisition
app.deviceFunctions.Acquisition(app,'stop');

[data,~,~,~,~,~,~,dataDarkTmp,B] = app.deviceFunctions.ReadBytesAvailable(app);
dataDark = mean(dataDarkTmp,2,'omitnan'); % really only need the lowest power level
B_Dark = B;
fclose(fileID);

% collect for all other states
srcram = createLEDPowerCalibrationSrcRAM_allPowerLevels( app.nSD);
app.deviceInformation.srcram = srcram ;
foo=find(srcram(1,:,32)==1);
nStates=foo(1);
%submit to device
rama = zeros(1024,32);
rama(nStates:end,9) = 1; % mark sequence end

uploadToRAM( stat, rama, 'a', false);
for isrcb = 1:7
    if stat.srcb_active(isrcb)
        uploadToRAM(stat, squeeze(srcram(isrcb,:,:)), 'src', false, isrcb);
    end
end

fnameDark=sprintf('%s\\%s\\LEDPowerCalibration_a01_%s.bin',foldname,foldname2,fname);
fileID=fopen(fnameDark,'w');
app.fstreamID=fileID;
% turn acquisition on
app.deviceFunctions.Acquisition(app,'start');
pause(1)
%stop acquisition
app.deviceFunctions.Acquisition(app,'stop');

% read raw byets
s=app.sp; %serial port
dev=app.deviceInformation; %config file
SD=app.nSD; %probe file
prevrbytes=app.rbytes; %remainder bytes from the previous read operation
fID=app.fstreamID;  %file streamer for debug mode; this can be used to stream the bytes directly to file as a backup
ba=s.NumBytesAvailable;
raw = read(s,ba,'uint8')';
if ~isempty(fID)
    fwrite(fID,raw,'uchar');
end
srcPowerLowHigh = ones(8 * 7, length(app.nSD.MeasList), 2, 'uint8');
for iPower = 1:7
    mappedIndices = mapToMeasurementList(srcram, measList, iPower*srcPowerLowHigh);
    [data,~,~,~,~,~,~,dataDarkTmp,B] = ReadBytesAvailable_powerCalib(app, raw, mappedIndices);
    if iPower == 1
        Bpow = zeros(size(B,2),size(B,3),7);
        % dataLEDPowerCalibration = zeros(size(dataDarkTmp,2),7);
    end
    dataLEDPowerCalibration(:,iPower) = squeeze(mean(data,2,'omitnan'));
    Bpow(:,:,iPower) = squeeze( mean(B,1,'omitnan') );
end
fclose(fileID);

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

% dual power setting

% Dual Power Cycling
% optimize power levels and update stateMap and stateIndices
app.deviceInformation.dataLEDPowerCalibration = dataLEDPowerCalibration;

% need to create srcPowerLowHigh(nSrc,nDet,nWav)
SD = app.nSD;
SD.sds_range = str2num( get(hAxes.sds,'value') );

[srcram, stateIndices, optPowerLevel, srcPowerLowHigh, dSig, srcModuleGroups] = LEDPowerCalibration_dualLevels(SD,dataLEDPowerCalibration,thresholds,flagSpatialMultiplex);
app.deviceInformation.srcram = srcram;
app.deviceInformation.stateIndices = stateIndices;
app.deviceInformation.optPowerLevel = optPowerLevel;
app.deviceInformation.srcPowerLowHigh = srcPowerLowHigh;
app.deviceInformation.dSig = dSig;
app.deviceInformation.srcModuleGroups = srcModuleGroups;
app.deviceInformation.flagSpatialMultiplex = flagSpatialMultiplex;
nSD = app.nSD;
save('dualPowerStateMapandIndices.mat','srcram','stateIndices','optPowerLevel','srcPowerLowHigh','dSig','Bpow','nSD','thresholds')

% check if source multiplexing
flagSpatialMultiplex = 0;
for ii=1:length(srcModuleGroups)
    if length(srcModuleGroups(ii))>1
        flagSpatialMultiplex = 1;
    end
end
set(hAxes.cb,'value',flagSpatialMultiplex);

foo=find(srcram(1,:,32)==1);
nStates=foo(1);

rama = zeros(1024,32);
rama(nStates:end,9) = 1; % mark sequence end
uploadToRAM(stat, rama, 'a', false);
for isrcb = 1:7
    if stat.srcb_active(isrcb)
        uploadToRAM(stat, squeeze(srcram(isrcb,:,:)), 'src', false, isrcb);
    end
end
stat.rama = rama;
stat.srcram = srcram;


% update rate
foo=find(srcram(1,:,32)==1);
nStates=foo(1);
fs=app.deviceInformation.stat.state_fs / nStates; 
app.deviceInformation.Rate=fs;
app.editRate.Value=app.deviceInformation.Rate;

%%
% report
reportSigDark( app.nSD, dataDark, B_Dark, hAxes );
reportSigVsSDS( measList(:,1:4), rhoSDS, dSig, hAxes );
set( hAxes.txa_pow,'value',sprintf(''));
