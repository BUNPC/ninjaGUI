function [stateMap, stateIndices, optPowerLevel, dSig, srcModuleGroups] = LEDPowerCalibration_dualLevels(SD,dataLEDPowerCalibration,thresholds)
%%
% get list of channels with each group of spatially multiplexed sources for
% each wavelength
ml = SD.MeasList;

%srcModuleGroups = {[1 2 3 4 5 6 7]};
srcModuleGroups = {[1 3 5],[2 4 6],[7]};

for iSg = 1:length(srcModuleGroups)
    for iWav = 1:2
        for iSrc = 1:8

            lstSMS{iSrc}{iWav}{iSg} = [];
            for iMod = 1:length(srcModuleGroups{iSg})
                lst = find(ml(:,1)==((srcModuleGroups{iSg}(iMod)-1)*8+iSrc) & ml(:,4)==iWav);
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
            optPowerLevel(iSrc,1,iWav,iSg) = ir(end);
            optPowerLevel(iSrc,2,iWav,iSg) = ic(end);

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

                lstGood = find( (dataLEDPowerCalibration(lst,iPow1)>threshLow & dataLEDPowerCalibration(lst,iPow1)<threshHigh) | (dataLEDPowerCalibration(lst,iPow2)>threshLow & dataLEDPowerCalibration(lst,iPow2)<threshHigh) );
                numDetGood2(iSrc,iPow1,iPow2,iWav) = length(lstGood);

            end
        end

        [ir,ic] = find( squeeze(numDetGood2(iSrc,:,:,iWav)) == max(max(numDetGood2(iSrc,:,:,iWav))) );
        optPowerLevelLow(iSrc,iWav) = ir(end);

    end
end


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

stateMap = zeros(1024,32);

lstS = unique(ml(:,1));

nSrcModules = 7;
iState = 1;

if 0 % spatial multiplexing all source modules simultaneously
    for iS = 1:8
        stateMap( iState, [1:3] ) = bitget( iS-1, 1:3 ); % Src Row Select
        stateMap( iState, 5:2:17 ) = 1; % Src Col Select. ODD wavelength
        stateMap( iState, 19:21 ) = bitget( optPowerLevel(iS,1,1), 1:3 ); % low power level

        iState = iState + 2;
        stateMap( iState, [1:3] ) = bitget( iS-1, 1:3 ); % Src Row Select
        stateMap( iState, 6:2:18 ) = 1; % Src Col Select. EVEN wavelength
        stateMap( iState, 19:21 ) = bitget( optPowerLevel(iS,1,2), 1:3 ); % low power level

        iState = iState + 2;
        stateMap( iState, [1:3] ) = bitget( iS-1, 1:3 ); % Src Row Select
        stateMap( iState, 5:2:17 ) = 1; % Src Col Select. ODD wavelength
        stateMap( iState, 19:21 ) = bitget( optPowerLevel(iS,2,1), 1:3 ); % high power level

        iState = iState + 2;
        stateMap( iState, [1:3] ) = bitget( iS-1, 1:3 ); % Src Row Select
        stateMap( iState, 6:2:18 ) = 1; % Src Col Select. EVEN wavelength
        stateMap( iState, 19:21 ) = bitget( optPowerLevel(iS,2,2), 1:3 ); % high power level

        iState = iState + 2;
    end

elseif 1 % spatial multiplex 3 groups of source modules; one dark state after all low power; one dark state after each high power source (after both wavelengths) 
    % low power state
    for iS = 1:8
        stateMap( iState, [1:3] ) = bitget( iS-1, 1:3 ); % Src Row Select
        stateMap( iState, 5:2:17 ) = 1; % Src Col Select. ODD wavelength
        stateMap( iState, 19:21 ) = bitget( optPowerLevelLow(iS,1), 1:3 ); % low power level
        iState = iState + 1;
        stateMap( iState, [1:3] ) = bitget( iS-1, 1:3 ); % Src Row Select
        stateMap( iState, 6:2:18 ) = 1; % Src Col Select. EVEN wavelength
        stateMap( iState, 19:21 ) = bitget( optPowerLevelLow(iS,2), 1:3 ); % low power level
        iState = iState + 1;

        for iSg = 1:length(srcModuleGroups)
            optPowerLevel(iS,1,1,:) = optPowerLevelLow(iS,1);
            optPowerLevel(iS,1,2,:) = optPowerLevelLow(iS,2);
        end
    end
    iState = iState + 1;

    % high power state
    for iSg = 1:length(srcModuleGroups)
        for iS = 1:8
            lstSMG = srcModuleGroups{iSg};
            stateMap( iState, [1:3] ) = bitget( iS-1, 1:3 ); % Src Row Select
            stateMap( iState, lstSMG*2+3 ) = 1; % Src Col Select. ODD wavelength
            stateMap( iState, 19:21 ) = bitget( optPowerLevel(iS,2,1,iSg), 1:3 ); % high power level
            iState = iState + 1;
            stateMap( iState, [1:3] ) = bitget( iS-1, 1:3 ); % Src Row Select
            stateMap( iState, lstSMG*2+4 ) = 1; % Src Col Select. EVEN wavelength
            stateMap( iState, 19:21 ) = bitget( optPowerLevel(iS,2,2,iSg), 1:3 ); % high power level
            iState = iState + 2;
        end
    end


end

stateMap((iState-1):end,27) = 1; % mark sequence end

stateIndices = mapToMeasurementList( stateMap, ml, srcPowerLowHigh );


