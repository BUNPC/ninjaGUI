function snirf1 = convertBintoSnirf_NN24( fName, flagSave, flagPlot, subLabel, sesLabel, taskLabel, runIndex )
% BIDS file name structure
%    sub-<label>[_ses-<label>]_task-<label>[_acq-<label>][_run-<index>]_nirs.snirf
% If no labels are provided, then the snirf file will be saved with the
% same fName.
% If subLabel and taskLabel is provided, then the snirf file will be saved
% with this BIDS compliant file name. If the optional labels sesLabel
% and/or runIndex are provided, then they will be included in the BIDS file
% name as well.

if ~exist('flagSave')
    flagSave = 0;
end

if ~exist('flagPlot')
    flagPlot = 0;
end

% load bin file
fID=fopen([fName,'.bin']);
inputBytes=fread(fID,'uint8');
fclose(fID);

% load sidecar file
load([fName,'_stateMap.mat']);
stateMap = load([fName,'_stateMap.mat']);

% load snirf file
SD = stateMap.nSD;

% ninjaGUIpy is saving 5 columns in SD.MeasList. Remove the 5th 
if size(SD.MeasList,2)>4
    SD.MeasList(:,5:end) = [];
end


subtractDark=1; % make it as 1 to subtract dark state

foo=find(stateMap.stateMap(1,:,32)==1);
nStates=foo(1);
fs=stateMap.devInfo.state_fs/nStates;
acc_active=stateMap.devInfo.acc_active;
aux_active=stateMap.devInfo.aux_active;
N_DETECTOR_BOARDS = stateMap.devInfo.N_DETECTOR_BOARDS;
if isfield(stateMap.devInfo,'N_IMU_BOARDS')
    N_IMU_BOARDS = stateMap.devInfo.N_IMU_BOARDS;
else
    N_IMU_BOARDS = 0;
end
stat_n_smp = stateMap.devInfo.stat.n_smp;
[B, unusedBytes, avgDet, imu_data, Auxdata, TGAdata, info] = translateNinja2022Bytesv3_BZ20230817_NN24(inputBytes,stateMap.stateMap,N_DETECTOR_BOARDS,N_IMU_BOARDS,acc_active,aux_active);
B=circshift(B,-1,3);
nLost = info.lostStates;
nExpected = length(info.estados) + nLost;
disp( sprintf('Lost %d states (%d gap events) amongst the %d expected (%.3f%%)', nLost, length(info.lstGaps), nExpected, 100*nLost/nExpected ) )
gaps.lostStates = nLost;                    % number of lost states (previously: number of gap events)
gaps.gapEvents = length(info.lstGaps);
gaps.totalStates = nExpected;               % received + lost (previously: received only)
% normslize data to mskr values between 0 and 1
%B = B./(app.deviceInformation.stat.n_smp*(2^15-1));
B = B./(stat_n_smp*(2^15-1));

% 
%indices=mapToMeasurementList_DualPower(stateMap,SD.MeasList);
indices = stateMap.stateIndices;

organizedData=nan(size(B,1),size(SD.MeasList,1));
organizedDataDark=nan(size(B,1),size(SD.MeasList,1));
% for loop is likely not the best way to do it

nStates=size(B,3);
cumDark=0;
for ki=1:size(SD.MeasList,1)    
    organizedData(:,ki)=B(:,indices(ki,2),indices(ki,1));        
    organizedDataDark(:,ki)=B(:,indices(ki,2),indices(ki,3));
    if subtractDark
%            darkState=B(:,indices(ki,2),indices(ki,1)+1);
%        darkState=B(:,indices(ki,2),indices(ki,3));
        %subtracts the next dark state of this source module: adjacent for high-power states; for low-power
        %states all modules fire together and the dark state follows the whole low-power block (up to ~16 states later)
        organizedData(:,ki)=organizedData(:,ki)-organizedDataDark(:,ki);
        cumDark=cumDark+mean(organizedDataDark(:,ki));
    end
end

% Signals at or below the dark level cannot be used. They are set to a small positive floor so log() stays
% finite, but the fraction of affected samples is kept per channel so that dead channels remain visible.
belowDarkFrac = sum(organizedData<0,1) / size(organizedData,1);
organizedData(organizedData<0)=1e-6;
if any(belowDarkFrac>0.5)
    warning('%d channels have more than 50%% of their samples at or below the dark level (set to 1e-6): likely dead or disconnected.', sum(belowDarkFrac>0.5))
end

t=(0:size(organizedData,1)-1)./fs;
temp1=sum(~isnan(organizedData)); 


% temp1=temp1(temp1>4);     
indi=1:median(temp1)-1; 
t=t(indi)';
d=organizedData(indi,:);
dDark=organizedDataDark(indi,:);
ml=SD.MeasList;

snirf1=SnirfClass(struct( ...
                'd',d, ...
                't',t, ...
                'SD',SD, ...
                'ml',ml ...
                )); 
snirf1.metaDataTags = MetaDataTagsClass();
snirf1.metaDataTags.tags.TimeUnit = 's';

% Verify whether the 2D optode positions from SD to SNIRF are correctly transferred.
% If not, copy them manually. 
% Note: This should be handled during SNIRF file creation above and needs to be fixed in HOMER.
if all(snirf1.probe.sourcePos2D(:) == 0) && ~all(SD.SrcPos2D(:) == 0)
    snirf1.probe.sourcePos2D = SD.SrcPos2D;
end

if all(snirf1.probe.detectorPos2D(:) == 0) && ~all(SD.DetPos2D(:) == 0)
    snirf1.probe.detectorPos2D = SD.DetPos2D;
end


% add sourcePower to the measurementList
flagWarning = 0;
powerLevelSetLowHigh = zeros(size(ml,1),1);
powerLevelSetting =  zeros(size(ml,1),1);
for iML = 1:size(ml,1)
    iS = ml(iML,1);
    iSrc = mod(iS-1,8)+1;
    iD = ml(iML,2);
    iW = ml(iML,4);

    % determine source group for the given ml(iML,1)
    iSrcModule = ceil(ml(iML,1)/8);
    iSg = 0;
    if ~iscell(stateMap.devInfo.srcModuleGroups)
        stateMap.devInfo.srcModuleGroups = {stateMap.devInfo.srcModuleGroups};
    end
    for ii=1:length(stateMap.devInfo.srcModuleGroups)
        if sum(ismember(stateMap.devInfo.srcModuleGroups{ii},iSrcModule))>0
            iSg = ii;
            break
        end
    end
    
    if isfield(devInfo,'srcPowerLowHigh')
        iLowHigh = devInfo.srcPowerLowHigh(ml(iML,1),iD,iW);  
    else % For backward compatibility, this should break if srcPowerLowHigh doesn't exist... Just spit out a wanring that we are assuming low high
        flagWarning = 1;
        rho = sqrt(sum((SD.SrcPos3D(iS,:)-SD.DetPos3D(iD,:)).^2));
        if rho<22 % FIXME - this is hard coded for the wholehead probe we are using
            iLowHigh = 1;
        else
            iLowHigh = 2;
        end
    end
    powerLevelSetLowHigh(iML) = iLowHigh;
    % optPowerLevel(slot, low/high, wavelength, k): k is the source MODULE for calibrations that set power
    % per module (size(optPowerLevel,4) > number of module groups), or the module GROUP for older calibrations
    if size(stateMap.devInfo.optPowerLevel,4) > length(stateMap.devInfo.srcModuleGroups)
        iOptDim4 = iSrcModule;
    else
        iOptDim4 = iSg;
    end
    iPL = stateMap.devInfo.optPowerLevel(iSrc,iLowHigh,iW,iOptDim4);
    snirf1.data.measurementList(iML).sourcePower = iPL;
    powerLevelSetting(iML) = iPL;
end
if flagWarning==1
    warning( 'srcPowerLowHigh was not saved in the _stateMap.mat file. Assuming high and low LED power settings.' )
end


% Add AUX data
if ~isempty(Auxdata)
%    Auxdata = Auxdata(1:floor(size(Auxdata,1)/size(d,1)):end,:);
%    if size(Auxdata,1) > length(t)
%        Auxdata = Auxdata(1:length(t),:);
%    end
    t_aux = [1:size(Auxdata,1)]'/devInfo.state_fs;

    aux_obj_digital = AuxClass(Auxdata(:,1),t_aux,'digital');
    aux_obj_analog1 = AuxClass(Auxdata(:,2),t_aux,'analog-1');
    aux_obj_analog2 = AuxClass(Auxdata(:,3),t_aux,'analog-2');
    aux_obj_dark    = AuxClass(dDark,t,'dark signal');
    snirf1.aux = [aux_obj_digital aux_obj_analog1 aux_obj_analog2 aux_obj_dark];
end

if acc_active
    t_acc =  [1:size(Auxdata,1)]'/devInfo.state_fs;
    temp_obj = AuxClass(TGAdata(:,1),t_acc,'temperature');
    gyro_data = TGAdata(:,2:4)*devInfo.stat.gyrofs;
    gyro_x_obj = AuxClass(gyro_data(:,1),t_acc,'GYRO_X');
    gyro_y_obj = AuxClass(gyro_data(:,2),t_acc,'GYRO_Y');
    gyro_z_obj = AuxClass(gyro_data(:,3),t_acc,'GYRO_Z');
    acc_data = TGAdata(:,5:7)*devInfo.stat.accfs;
    acc_x_obj = AuxClass(acc_data(:,1),t_acc,'ACCEL_X');
    acc_y_obj = AuxClass(acc_data(:,2),t_acc,'ACCEL_Y');
    acc_z_obj = AuxClass(acc_data(:,3),t_acc,'ACCEL_Z');
    snirf1.aux = [snirf1.aux temp_obj gyro_x_obj gyro_y_obj gyro_z_obj acc_x_obj acc_y_obj acc_z_obj]; 
end

if N_IMU_BOARDS > 0
    for i_board = 1:N_IMU_BOARDS
        for i_imu = 1:8
            t_acc =  [1:size(imu_data,1)]'/(devInfo.state_fs/8);
            temp_obj = AuxClass(imu_data(:,i_imu,i_board,1),t_acc,sprintf('temperature_%d_%d',i_imu,i_board));
            gyro_data = squeeze(imu_data(:,i_imu,i_board,2:4)*devInfo.stat.gyrofs);
            gyro_x_obj = AuxClass(gyro_data(:,1),t_acc,sprintf('GYRO_X_%d_%d',i_imu,i_board));
            gyro_y_obj = AuxClass(gyro_data(:,2),t_acc,sprintf('GYRO_Y_%d_%d',i_imu,i_board));
            gyro_z_obj = AuxClass(gyro_data(:,3),t_acc,sprintf('GYRO_Z_%d_%d',i_imu,i_board));
            acc_data = squeeze(imu_data(:,i_imu,i_board,5:7)*devInfo.stat.accfs);
            acc_x_obj = AuxClass(acc_data(:,1),t_acc,sprintf('ACCEL_X_%d_%d',i_imu,i_board));
            acc_y_obj = AuxClass(acc_data(:,2),t_acc,sprintf('ACCEL_Y_%d_%d',i_imu,i_board));
            acc_z_obj = AuxClass(acc_data(:,3),t_acc,sprintf('ACCEL_Z_%d_%d',i_imu,i_board));
            snirf1.aux = [snirf1.aux temp_obj gyro_x_obj gyro_y_obj gyro_z_obj acc_x_obj acc_y_obj acc_z_obj]; 
        end
    end
end

% Add the calibration data to the AUX
try
    dataSDWP_LowHigh = convertBintoSnirf_NN24_LEDPowerCalibrationTools( fName, stateMap );
    if flagPlot
        convertBintoSnirfv3_plotSigVsDistance( SD, dataSDWP_LowHigh, powerLevelSetting)
        convertBintoSnirfv3_crossTalk( stateMap, dataSDWP_LowHigh )
    end
catch ME
    warning('LEDPowerCalibration data could not be processed (%s: %s). dataSDWP_LowHigh will be empty.', ME.identifier, ME.message)
    dataSDWP_LowHigh = [];
end


%dataSDWP_w1low_obj = AuxClass( dataSDWP_LowHigh(:,:,1,1), [1:stateMap.nSD.nSrcs]','Calibration, Wavelength 1, Low Power' );
%dataSDWP_w1high_obj = AuxClass( dataSDWP_LowHigh(:,:,1,2), [1:stateMap.nSD.nSrcs]','Calibration, Wavelength 1, High Power' );
%dataSDWP_w2low_obj = AuxClass( dataSDWP_LowHigh(:,:,2,1), [1:stateMap.nSD.nSrcs]','Calibration, Wavelength 2, Low Power' );
%dataSDWP_w2high_obj = AuxClass( dataSDWP_LowHigh(:,:,2,2), [1:stateMap.nSD.nSrcs]','Calibration, Wavelength 2, High Power' );
%powerLevelSetLowHigh_obj = AuxClass( powerLevelSetLowHigh, [1:size(ml,1)]', 'LED Power Level Low or High');

%snirf1.aux = [snirf1.aux dataSDWP_w1low_obj dataSDWP_w1high_obj dataSDWP_w2low_obj dataSDWP_w2high_obj powerLevelSetLowHigh_obj];


% SAVE

if flagSave

    % subLabel, sesLabel, taskLabel, runIndex )
    % BIDS file name structure
    %    sub-<label>[_ses-<label>]_task-<label>[_acq-<label>][_run-<index>]_nirs.snirf
    if ~exist('subLabel','var')
        subLabel = '';
    end
    if ~exist('sesLabel','var')
        sesLabel = '';
    end
    if ~exist('taskLabel','var')
        taskLabel = '';
    end
    if ~exist('runIndex','var')
        runIndex = '';
    end

    [folder, baseFileNameNoExt, extension] = fileparts(fName);
    baseFileNameNoExt_orig = baseFileNameNoExt;
    subj_path = '';
    if ~isempty(subLabel) && ~isempty(taskLabel)
        subj_path = ['sub-' subLabel filesep 'nirs' filesep];
        subj_path0 = ['sub-' subLabel filesep];
        if isempty(sesLabel)
            baseFileNameNoExt = sprintf('sub-%s_task-%s', subLabel, taskLabel );
        else
            baseFileNameNoExt = sprintf('sub-%s_ses-%s_task-%s', subLabel, sesLabel, taskLabel );
        end
        if ~isempty(runIndex)
            baseFileNameNoExt = sprintf('%s_run-%s_nirs', baseFileNameNoExt, runIndex );
        else
            baseFileNameNoExt = sprintf('%s_nirs', baseFileNameNoExt );
        end
    end

    if ~isempty(subj_path)
        if exist(['..' filesep '..' filesep '..' filesep subj_path], 'dir')
            folder = ['..' filesep '..' filesep '..' filesep subj_path];
        elseif exist(['..' filesep '..' filesep '..' filesep 'sourcedata'], 'dir') % e.g. /sourcedata/raw/sub-id
            folder = ['..' filesep '..' filesep '..' filesep subj_path];
            if ~exist( ['..' filesep '..' filesep '..' filesep subj_path0], 'dir' )
                mkdir( ['..' filesep '..' filesep '..' filesep subj_path0] );
            end
            if ~exist( ['..' filesep '..' filesep '..' filesep subj_path], 'dir' )
                mkdir( ['..' filesep '..' filesep '..' filesep subj_path] );
            end
        elseif exist(['..' filesep '..' filesep '..' filesep '..' filesep 'sourcedata'], 'dir') % e.g. /sourcedata/raw/sub-id/nirs
            folder = ['..' filesep '..' filesep '..' filesep '..' filesep subj_path];
            if ~exist( ['..' filesep '..' filesep '..' filesep '..' filesep subj_path0], 'dir' )
                mkdir( ['..' filesep '..' filesep '..' filesep '..' filesep subj_path0] );
            end
            if ~exist( ['..' filesep '..' filesep '..' filesep '..' filesep subj_path], 'dir' )
                mkdir( ['..' filesep '..' filesep '..' filesep '..' filesep subj_path] );
            end
        end
    end
    snirf1.Save(fullfile(folder, [baseFileNameNoExt '.snirf']))
%    snirf1.Save([folder filesep baseFileNameNoExt '.snirf'])

    % Save Sidecar File
%     if ~isempty(folder)
%         fileSide = [folder filesep baseFileNameNoExt '_NN24sidecar.mat'];
%     else
%         fileSide = [baseFileNameNoExt '_NN24sidecar.mat'];
%     end
% 
%     % stateMap.devInfo.optPowerLevel( Src #, PowerLevel (1-L, 2-H), wavelength, Src Module (or module group for older calibrations) )
%     save(fileSide,'stateMap','info','dataSDWP_LowHigh','powerLevelSetLowHigh','powerLevelSetting')


    SD = stateMap.nSD;
    SDo.SrcPos3D = SD.SrcPos3D;
    SDo.DetPos3D = SD.DetPos3D;
    if isfield(SD,'SrcPos2D')
        SDo.SrcPos2D = SD.SrcPos2D;
        SDo.DetPos2D = SD.DetPos2D;
    else
        SDo.SrcPos2D = SD.SrcPos;
        SDo.DetPos2D = SD.DetPos;
    end
    SDo.Lambda = SD.Lambda;
    SDo.MeasList = SD.MeasList(:,1:4);   % same 4 columns as the snirf (ninjaGUIpy adds a 5th: rho)

    if ~isempty(folder)
        fileSide = fullfile(folder, [baseFileNameNoExt '.json']);
    else
        fileSide = [baseFileNameNoExt '.json'];
    end
    fid = fopen(fileSide,'w');
    fprintf( fid, '{\n');
    fprintf( fid, '%s,\n', ['"SourceDataRawFileName": ' jsonencode(baseFileNameNoExt_orig)] );
    fprintf( fid, '%s,\n', ['"SamplingFrequency": ' jsonencode(fs)] );
    fprintf( fid, '%s,\n', ['"NIRSChannelCount": ' jsonencode(size(ml,1))] );
    fprintf( fid, '%s,\n', ['"NIRSSourceOptodeCount": ' jsonencode(max(nSD.MeasList(:,1)))] );
    fprintf( fid, '%s,\n', ['"NIRSDetectorOptodeCount": ' jsonencode(max(nSD.MeasList(:,2)))] );
    fprintf( fid, '%s,\n', ['"RecordingDuration": ' jsonencode(t(end))] );
    fprintf( fid, '%s,\n', ['"SD": ' jsonencode(SDo,"PrettyPrint",true)] );
    fprintf( fid, '%s,\n', ['"powerLevelSetting": ' jsonencode(powerLevelSetting)] );
    fprintf( fid, '%s,\n', ['"powerLevelSetLowHigh": ' jsonencode(powerLevelSetLowHigh)] );
    fprintf( fid, '%s,\n', ['"srcModuleGroups": ' jsonencode(stateMap.devInfo.srcModuleGroups,"PrettyPrint",true)] );
    fprintf( fid, '%s,\n', ['"dataSDWP_LowHigh": ' jsonencode(dataSDWP_LowHigh)] );
    fprintf( fid, '%s,\n', ['"BelowDarkFraction": ' jsonencode(belowDarkFrac)] );

    % If thresholds exists, Gaps must end with a comma (because more fields follow)
    hasThresholds = isfield(stateMap.devInfo,'thresholds');
    
    if hasThresholds
        fprintf( fid, '%s,\n', ['"Gaps": ' jsonencode(gaps, "PrettyPrint", true)] );
        thresholds = stateMap.devInfo.thresholds;
        fprintf( fid, '%s\n',  ['"thresholds": ' jsonencode(thresholds)] );  % fixed key spelling
    else
        fprintf( fid, '%s\n',  ['"Gaps": ' jsonencode(gaps, "PrettyPrint", true)] );
    end
    fprintf( fid, '}');
    fclose( fid );
    
    % these additional fields will come later on in the pipeline
    %   "InstitutionName": "Macquarie University. Australian Hearing Hub",
    %   InstitutionalDepartmentName
    %   "Manufacturer": "NIRx",
    %   "ManufacturersModelName": "NIRScout",
    %   SoftwareVersions
    %   DeviceSerialNumber
    %   "CapManafacturer": "NIRx",
    %   "CapManufacturersModelName": "Headband with print (S-M)",
    %   "NIRSPlacementScheme": "n/a",



end