function [srcram, stateIndices, optPowerLevel, srcPowerLowHigh, dSig, srcModuleGroups] = LEDPowerCalibration_dualLevels(SD,dataLEDPowerCalibration,thresholds,flagSpatialMultiplex)
% stateMap (# states x 32 bits) - This is RAM A
% stateIndices (# ml x 3) - Tell us which state to use for each
%       measurement (1st column), the dark state to use for that
%       measurement (3rd column), and which detector (2nd column)
% optPowerLevel (# srcs x 2 power levels x 2 wavelengths x # source groups)
%       - This is the power level used for each source in each source group
% srcPowerLowHigh (# srcs x # dets x # wavelengths) - tells us the optimal
%       power setting to choose for each source and detector pair, used to
%       get stateIndices 
% dSig (# ml x 1) - This is the "optima"l calibration signal for each
%       measurement in the measurement list. By "optimal" we mean for the
%       power levels choosen for that given measurement.
% srcModuleGroups - A list of the sources in each module

% get rhoSDS
rhoSDS = zeros(size(SD.MeasList,1),1);
for iML = 1:size(SD.MeasList,1)
    iS = SD.MeasList(iML,1);
    iD = SD.MeasList(iML,2);
    rhoSDS(iML) = sum( (SD.SrcPos3D(iS,:) - SD.DetPos3D(iD,:)).^2 ).^0.5;
end


%%
% get list of channels with each group of spatially multiplexed sources for
% each wavelength
ml = SD.MeasList;

% rhoSDS to 5th column of measList
ml(:,5) = rhoSDS;

%srcModuleGroups = {[1 2 3 4 5 6 7]};
if flagSpatialMultiplex==1 & SD.nSrcs==56
    srcModuleGroups = {[1 3 5],[2 4 6],[7]};
else
    srcModuleGroups = {1,2,3,4,5,6,7};
    srcModuleGroups = srcModuleGroups( 1:ceil((SD.nSrcs-0.1)/8) );
end

% Get the list of indices into the measlist for measurements for a given
% LED in a srcModuleGroup.
% This is used for finding the optimal combination of low and high power
% settings.
% It also considers the range of source detector separations if specified
% by the user in the calibration GUI.
for iSg = 1:length(srcModuleGroups)
    for iWav = 1:2
        for iSrc = 1:8

            lstSMS{iSrc}{iWav}{iSg} = [];
            for iMod = 1:length(srcModuleGroups{iSg})
                lst = find(ml(:,1)==((srcModuleGroups{iSg}(iMod)-1)*8+iSrc) & ml(:,4)==iWav & rhoSDS>=SD.sds_range(1) & rhoSDS<=SD.sds_range(2) );
                lstSMS{iSrc}{iWav}{iSg} = [lstSMS{iSrc}{iWav}{iSg}; lst];
            end

        end
    end
end

%%
% Now let's consider dual power levels
% and find optimal combination that gives us the most channels that pass
% the thresholds
%
% optPowerLevel(nSrc,2,nWav) tells us the two optimal power levels for each
% source group at each wavelength
%
% SrcPowerLowHigh(nSrc,nDet,nWav) tells us the optimal power setting to
% choose for each source and detector pair, used to get stateIndices
%

threshHigh = 10^(thresholds(2)/20);
threshLow  = 10^(thresholds(1)/20);

for iSg = 1:length(srcModuleGroups)
    numDetGood2  = zeros(8,7,7,2);
    for iWav = 1:2
        for iSrc = 1:8
            for iPow1 = 1:6
                for iPow2 = (iPow1+1):7

                    lst = lstSMS{iSrc}{iWav}{iSg};

                    lstGood = find( (dataLEDPowerCalibration(lst,iPow1)>threshLow & dataLEDPowerCalibration(lst,iPow1)<threshHigh) | (dataLEDPowerCalibration(lst,iPow2)>threshLow & dataLEDPowerCalibration(lst,iPow2)<threshHigh) );
                    numDetGood2(iSrc,iPow1,iPow2,iWav) = length(lstGood);

                end
            end

            [ir,ic] = find( squeeze(numDetGood2(iSrc,:,:,iWav)) == max(max(numDetGood2(iSrc,:,:,iWav))) );
            if 1
                optPowerLevel(iSrc,1,iWav,iSg) = ir(end);
                optPowerLevel(iSrc,2,iWav,iSg) = ic(end);
            else   % HACK TO HARD SET THE POWER LEVEL
                optPowerLevel(iSrc,1,iWav,iSg) = 7;
                optPowerLevel(iSrc,2,iWav,iSg) = 7;
            end

        end
    end
end

%find low power level optimization for all source modules
numDetGood2  = zeros(8,7,7,2);
for iWav = 1:2
    for iSrc = 1:8
        for iPow1 = 1:6
            for iPow2 = (iPow1+1):7

                lst = [];
                for iSg = 1:size(lstSMS,3)
                    lst = [lst lstSMS{iSrc}{iWav}{iSg}];
                end

                % WHY IS THIS CONSIDERING POW2 WHEN IT DOESN'T SEEMED TO BE
                % USED BELOW??? DAB Aug 2, 2024
                lstGood = find( (dataLEDPowerCalibration(lst,iPow1)>threshLow & dataLEDPowerCalibration(lst,iPow1)<threshHigh) | (dataLEDPowerCalibration(lst,iPow2)>threshLow & dataLEDPowerCalibration(lst,iPow2)<threshHigh) );
                numDetGood2(iSrc,iPow1,iPow2,iWav) = length(lstGood);

            end
        end

        [ir,ic] = find( squeeze(numDetGood2(iSrc,:,:,iWav)) == max(max(numDetGood2(iSrc,:,:,iWav))) );
        optPowerLevelLow(iSrc,iWav) = ir(end); % THIS IS ONLY USING POW1!!! DAB AUG 2, 2024

    end
end


% Determine which power level to use for a given measurement in the ML
% This is recorded in srcPowerLowHigh(iS,iD,iW)
dSig = zeros(size(ml,1),1);
for iML = 1:size(ml,1)
    iS = mod(ml(iML,1)-1,8)+1;
    iD = ml(iML,2);
    iW = ml(iML,4);

    % determine source group for the given ml(iML,1)
    iSrcModule = ceil(ml(iML,1)/8);
    iSg = 0;
    for ii=1:length(srcModuleGroups)
        if sum(ismember(srcModuleGroups{ii},iSrcModule))>0
            iSg = ii;
            break
        end
    end
    
    iPL1 = optPowerLevel(iS,1,iW,iSg);
    iPL2 = optPowerLevel(iS,2,iW,iSg);
    
    if (dataLEDPowerCalibration(iML,iPL2)>threshLow & dataLEDPowerCalibration(iML,iPL2)<threshHigh) 
        srcPowerLowHigh(ml(iML,1),iD,iW) = 2;
        dSig(iML) = dataLEDPowerCalibration(iML,iPL2);
    else
        srcPowerLowHigh(ml(iML,1),iD,iW) = 1;
        dSig(iML) = dataLEDPowerCalibration(iML,iPL1);
    end
    
end

%%
% create the statemap

srcram = zeros(7,1024,32);
srcram(:,:,21) = 1;

lstS = unique(ml(:,1));

nSrcModules = 7;
iState = 1;
maxPower = round(logspace(3,log10(2^16-1),7));

% spatial multiplex 3 groups of source modules; one dark state after all low power; one dark state after each high power source (after both wavelengths)
% low power state
for iS = 1:8

    iPower = optPowerLevelLow(iS,1);
    for iSrcMod = 1:7 % FIXME - loop over number of source modules
        srcram( iSrcMod, iState, 1:16 ) = bitget( maxPower(optPowerLevelLow(iS,1)), 1:16, 'uint16' ); % set the power
        srcram( iSrcMod, iState, 17:20) = bitget( (iS-1)*2, 1:4, 'uint16' ); % select the source for wavelength 1
        srcram( iSrcMod, iState, 21) = 0;
    end
    iState = iState + 1;

    iPower = optPowerLevelLow(iS,2);
    for iSrcMod = 1:7 % FIXME - loop over number of source modules
        srcram( iSrcMod, iState, 1:16 ) = bitget( maxPower(optPowerLevelLow(iS,2)), 1:16, 'uint16' ); % set the power
        srcram( iSrcMod, iState, 17:20) = bitget( (iS-1)*2+1, 1:4, 'uint16' ); % select the source for wavelength 2
        srcram( iSrcMod, iState, 21) = 0;
    end
    iState = iState + 1; % +2 to have a dark state

    % DELETE WHEN DONE MAKING CHANGES POWER LEVELS
    %         stateMap( iState, [1:3] ) = bitget( iS-1, 1:3 ); % Src Row Select
    %         stateMap( iState, 5:2:17 ) = 1; % Src Col Select. ODD wavelength
    %         stateMap( iState, 19:21 ) = bitget( optPowerLevelLow(iS,1), 1:3 ); % low power level
    %         iState = iState + 1;
    %         stateMap( iState, [1:3] ) = bitget( iS-1, 1:3 ); % Src Row Select
    %         stateMap( iState, 6:2:18 ) = 1; % Src Col Select. EVEN wavelength
    %         stateMap( iState, 19:21 ) = bitget( optPowerLevelLow(iS,2), 1:3 ); % low power level
    %         iState = iState + 1;

    for iSg = 1:length(srcModuleGroups)
        optPowerLevel(iS,1,1,iSg) = optPowerLevelLow(iS,1);
        optPowerLevel(iS,1,2,iSg) = optPowerLevelLow(iS,2);
    end
end
iState = iState + 1;

% high power state
for iSg = 1:length(srcModuleGroups)
    for iS = 1:8
        lstSMG = srcModuleGroups{iSg};

        for iSrcMod = 1:length(lstSMG)
            srcram( lstSMG(iSrcMod), iState, 1:16 ) = bitget( maxPower(optPowerLevel(iS,2,1,iSg)), 1:16, 'uint16' ); % set the power
            srcram( lstSMG(iSrcMod), iState, 17:20) = bitget( (iS-1)*2, 1:4, 'uint16' ); % select the source for wavelength 1
            srcram( lstSMG(iSrcMod), iState, 21) = 0;
        end
        iState = iState + 1;
        for iSrcMod = 1:length(lstSMG)
            srcram( lstSMG(iSrcMod), iState, 1:16 ) = bitget( maxPower(optPowerLevel(iS,2,2,iSg)), 1:16, 'uint16' ); % set the power
            srcram( lstSMG(iSrcMod), iState, 17:20) = bitget( (iS-1)*2+1, 1:4, 'uint16' ); % select the source for wavelength 2
            srcram( lstSMG(iSrcMod), iState, 21) = 0;
        end
        iState = iState + 2;

        % DELETE WHEN DONE MAKING CHANGES POWER LEVELS
        %             stateMap( iState, [1:3] ) = bitget( iS-1, 1:3 ); % Src Row Select
        %             stateMap( iState, lstSMG*2+3 ) = 1; % Src Col Select. ODD wavelength
        %             stateMap( iState, 19:21 ) = bitget( optPowerLevel(iS,2,1,iSg), 1:3 ); % high power level
        %             iState = iState + 1;
        %             stateMap( iState, [1:3] ) = bitget( iS-1, 1:3 ); % Src Row Select
        %             stateMap( iState, lstSMG*2+4 ) = 1; % Src Col Select. EVEN wavelength
        %             stateMap( iState, 19:21 ) = bitget( optPowerLevel(iS,2,2,iSg), 1:3 ); % high power level
        %             iState = iState + 2;
    end
end



srcram(:, (iState-1):end,32) = 1; % mark sequence end

stateIndices = mapToMeasurementList( srcram, ml, srcPowerLowHigh );


