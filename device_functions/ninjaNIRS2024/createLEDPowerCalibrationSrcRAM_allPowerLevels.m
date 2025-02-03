function srcram = createLEDPowerCalibrationSrcRAM_allPowerLevels( SD)

    srcram = zeros(7,1024,32);
    srcram(:,:,21) = 1;
    srcram(:,:,31) = 1; % using this bit as a hack for identifying source 0 when we look at 5 bits in mapToMeasurementList()
    
    lstS = unique(SD.MeasList(:,1));
    
    % loop over unique sources
    % fill in odd states and leave even states as dark states
    % alternate between two wavelengths for each state
    
    iState = 1;
    
    maxPower = round(logspace(2,log10(2^16-1),7));

    for iS = 1:length(lstS)
        iSrcMod = ceil((lstS(iS)-0.1)/8); 
        iSrc = mod(lstS(iS)-1,8);
        for iPower = 1:length(maxPower)
            srcram(iSrcMod, iState, 1:16) = bitget(maxPower(iPower), 1:16, 'uint16');
            srcram(iSrcMod, iState, 17:20) = bitget(iSrc*2, 1:4, 'uint16');
            srcram(iSrcMod, iState, 21) = 0;
            srcram(iSrcMod, iState, 31) = 0;
            iState = iState + 1;
        end

        iState = iState + 1;
        for iPower = 1:length(maxPower)
            srcram(iSrcMod, iState, 1:16) = bitget(maxPower(iPower), 1:16, 'uint16');
            srcram(iSrcMod, iState, 17:20) = bitget(iSrc*2+1, 1:4, 'uint16');
            srcram(iSrcMod, iState, 21) = 0;
            srcram(iSrcMod, iState, 31) = 0;
            iState = iState + 1;
        end
        iState = iState + 1;
    end
    srcram(:,(iState-1):end,32) = 1; % mark sequence end
end

