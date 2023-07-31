function [stateMap, stateIndices, optPowerLevel] = LEDPowerCalibration_dualLevels(SD,dataLEDPowerCalibration)
%%
% get list of channels with each group of spatially multiplexed sources for
% each wavelength
ml = SD.MeasList;

for iWav = 1:2
    for iSrc = 1:8
        
        lstSMS{iSrc}{iWav} = [];
        for iMod = 1:7
            lst = find(ml(:,1)==((iMod-1)*8+iSrc) & ml(:,4)==iWav);
            lstSMS{iSrc}{iWav} = [lstSMS{iSrc}{iWav}; lst];
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
numDetGood2  = zeros(8,7,7,2);

threshHigh = 4e6;
threshLow  = 4e4;

for iWav = 1:2
    for iSrc = 1:8
        for iPow1 = 1:6
            for iPow2 = (iPow1+1):7
                
                lst = lstSMS{iSrc}{iWav};
                
                lstGood = find( (dataLEDPowerCalibration(lst,1,iPow1)>threshLow & dataLEDPowerCalibration(lst,1,iPow1)<threshHigh) | (dataLEDPowerCalibration(lst,1,iPow2)>threshLow & dataLEDPowerCalibration(lst,1,iPow2)<threshHigh) ); 
                numDetGood2(iSrc,iPow1,iPow2,iWav) = length(lstGood);                
                
            end
        end
        
        [ir,ic] = find( squeeze(numDetGood2(iSrc,:,:,iWav)) == max(max(numDetGood2(iSrc,:,:,iWav))) );
        optPowerLevel(iSrc,1,iWav) = ir(end);
        optPowerLevel(iSrc,2,iWav) = ic(end);
        
    end
end


for iML = 1:size(ml,1)
    iS = mod(ml(iML,1)-1,8)+1;
    iD = ml(iML,2);
    iW = ml(iML,4);
    
    iPL1 = optPowerLevel(iS,1,iW);
    iPL2 = optPowerLevel(iS,2,iW);
    
    if (dataLEDPowerCalibration(iML,1,iPL2)>threshLow & dataLEDPowerCalibration(iML,1,iPL2)<threshHigh) 
        srcPowerLowHigh(iS,iD,iW) = 2;
    else
        srcPowerLowHigh(iS,iD,iW) = 1;
    end
    
end

%%
% create the statemap

stateMap = zeros(1024,32);

lstS = unique(ml(:,1));

nSrcModules = 7;
iState = 1;
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

stateMap((iState-1):end,27) = 1; % mark sequence end

stateIndices = mapToMeasurementList( stateMap, ml, srcPowerLowHigh );


