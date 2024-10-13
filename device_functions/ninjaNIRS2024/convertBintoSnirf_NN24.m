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

subtractDark=1; % make it as 1 to subtract dark state

foo=find(stateMap.stateMap(1,:,32)==1);
nStates=foo(1);
fs=stateMap.devInfo.state_fs/nStates;
acc_active=stateMap.devInfo.acc_active;
aux_active=stateMap.devInfo.aux_active;
N_DETECTOR_BOARDS = stateMap.devInfo.N_DETECTOR_BOARDS;
stat_n_smp = stateMap.devInfo.stat.n_smp;
[B, unusedBytes, avgDet, Auxdata, TGAdata, info] = translateNinja2022Bytesv3_BZ20230817_NN24(inputBytes,stateMap.stateMap,N_DETECTOR_BOARDS,acc_active,aux_active);
B=circshift(B,-1,3);

disp( sprintf('Lost %d states amongst the %d that were recorded (%.1f%%)',length(info.lstGaps),length(info.estados),length(info.lstGaps)/(length(info.lstGaps)+length(info.estados)) ) )

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
        %subtracts the adjacent state (after the current). Assumes
        %there is a dark state between each active state
        organizedData(:,ki)=organizedData(:,ki)-organizedDataDark(:,ki);
        cumDark=cumDark+mean(organizedDataDark(:,ki));
    end
end

organizedData(organizedData<0)=1e-6;

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

% add sourcePower to the measurementList
flagWarning = 0;
powerLevelSetLowHigh = zeros(size(ml,1),1);
for iML = 1:size(ml,1)
    iS = ml(iML,1);
    iSrc = mod(iS-1,8)+1;
    iD = ml(iML,2);
    iW = ml(iML,4);

    % determine source group for the given ml(iML,1)
    iSrcModule = ceil(ml(iML,1)/8);
    iSg = 0;
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
        rho = sqrt(sum(SD.SrcPos3D(iS,:)-SD.DetPos3D(iD,:)).^2);
        if rho<22 % FIXME - this is hard coded for the wholehead probe we are using
            iLowHigh = 1;
        else
            iLowHigh = 2;
        end
    end
    powerLevelSetLowHigh(iML) = iLowHigh;
    iPL = stateMap.devInfo.optPowerLevel(iSrc,iLowHigh,iW,iSg);
    snirf1.data.measurementList(iML).sourcePower = iPL;
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


% Add the calibration data to the AUX
dataSDWP_LowHigh = convertBintoSnirf_NN24_LEDPowerCalibrationTools( fName, stateMap );

if flagPlot
    convertBintoSnirfv3_plotSigVsDistance( SD, dataSDWP_LowHigh)
    convertBintoSnirfv3_crossTalk( stateMap, dataSDWP_LowHigh )
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
    if ~exist('subLabel')
        subLabel = '';
    end
    if ~exist('sesLabel')
        subLabel = '';
    end
    if ~exist('taskLabel')
        subLabel = '';
    end
    if ~exist('runIndex')
        subLabel = '';
    end

    [folder, baseFileNameNoExt, extension] = fileparts(fName);
    if ~isempty(subLabel) && ~isempty(taskLabel)
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

    snirf1.Save([folder baseFileNameNoExt '.snirf'])
%    snirf1.Save([folder filesep baseFileNameNoExt '.snirf'])

    % Save Sidecar File
    if ~isempty(folder)
        fileSide = [folder filesep baseFileNameNoExt '_sidecar.mat'];
    else
        fileSide = [baseFileNameNoExt '_NN24sidecar.mat'];
    end
    save(fileSide,'stateMap','info','dataSDWP_LowHigh','powerLevelSetLowHigh')

end