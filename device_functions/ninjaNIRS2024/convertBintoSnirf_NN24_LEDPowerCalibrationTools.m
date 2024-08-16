function dataSDWP_LowHigh = convertBintoSnirfv3_LEDPowerCalibrationTools( fname, stateMap )


% file name part for acquired run
fNamePart = fname(15:end); %  '2024-07-18-10-26-20';

SD = stateMap.nSD;


%%
% Load the prior calibration data

% I need the stateMap for the acquired file and then find the
% LEDPowerCalibration time stamp just before the acquired file
files=dir(['LEDPowerCalibration',filesep,'LEDPowerCalibration_00_*.bin']);
iFileSel = [];
for iFile = 1:length(files)
    if files(iFile).name < sprintf("LEDPowerCalibration_00_%s.bin",fNamePart)
        iFileSel = iFile;
    end
end

if ~isempty(iFileSel)
    fNamePartCal = files(iFileSel).name(24:end);
else
    error('Could not find an appropriate LEDPowerCalibration dataset')
end

for iPowerLevel = 1:7
    fName = sprintf('LEDPowerCalibration_%02d_%s',iPowerLevel,fNamePartCal);

    fID=fopen(['LEDPowerCalibration',filesep,fName]);
    inputBytes=fread(fID,'uint8');
    fclose(fID);

    % translateBytes

    srcramCal = createLEDPowerCalibrationSrcRAM( SD, iPowerLevel );


    subtractDark=1; % make it as 1 to subtract dark state
    % for LED power calibration we do not subtract it

    foo=find(srcramCal(1,:,32)==1);
    nStates=foo(1);
    fs=stateMap.devInfo.state_fs/nStates;
    acc_active=stateMap.devInfo.acc_active;
    aux_active=stateMap.devInfo.aux_active;
    N_DETECTOR_BOARDS =stateMap.devInfo.N_DETECTOR_BOARDS;
    stat_n_smp = stateMap.devInfo.stat.n_smp;
    [B, unusedBytes, avgDet, Auxdata, TGAdata, info] = translateNinja2022Bytesv3_BZ20230817_NN24(inputBytes,srcramCal,N_DETECTOR_BOARDS,acc_active,aux_active);
    B=circshift(B,-1,3);

    disp( sprintf('Power Level %d - Lost %d states amongst the %d that were recorded (%.1f%%)',iPowerLevel, length(info.lstGaps),length(info.estados),length(info.lstGaps)/(length(info.lstGaps)+length(info.estados)) ) )

    % normslize data to mskr values between 0 and 1
    %B = B./(app.deviceInformation.stat.n_smp*(2^15-1));
    B = B./(stat_n_smp*(2^15-1));
    
    % get dataSDWP (#s,#d,#wl,#power levels)
    if iPowerLevel == 1
        dataSDWP = zeros(size(B,3)/4,size(B,2),2,7);
        dataSDWPdark = zeros(size(B,3)/4,size(B,2),2,7);
    end
    B = squeeze(mean(B,1,'omitnan'))'; % mean temporal samples and transpose to get #states x #d
    Bdark = B(2:2:end,:); % get the dark states
    B = B(1:2:end,:); % strip the dark states
    dataSDWP(:,:,1,iPowerLevel) = B(1:2:end,:);
    dataSDWP(:,:,2,iPowerLevel) = B(2:2:end,:);
    dataSDWPdark(:,:,1,iPowerLevel) = Bdark(1:2:end,:);
    dataSDWPdark(:,:,2,iPowerLevel) = Bdark(2:2:end,:);
end



%%
% Get the calibration data for the Low and High LED Powers utilized in the
% measurements
dataSDWP_LowHigh = zeros( size(dataSDWP,1), size(dataSDWP,2), 2, 2);
for iS = 1:SD.nSrcs

    % determine source group for the given iS
    iSrcModule = ceil(iS/8);
    iSrc = iS - (iSrcModule-1)*8;
    iSg = 0;
    for ii=1:length(stateMap.devInfo.srcModuleGroups)
        if sum(ismember(stateMap.devInfo.srcModuleGroups{ii},iSrcModule))>0
            iSg = ii;
            break
        end
    end

    for iW = 1:2
        for iPL = 1:2
            iPowerLevel = stateMap.devInfo.optPowerLevel(iSrc,iPL,iW,iSg);   
            dataSDWP_LowHigh( iS, :, iW, iPL) = dataSDWP( iS, :, iW, iPowerLevel) - dataSDWPdark( iS, :, iW, iPowerLevel);
        end
    end
end


