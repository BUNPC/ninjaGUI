function srcram = createLEDPowerCalibrationSrcRAM( SD, iPower )


srcram = zeros(7,1024,32);
srcram(:,:,21) = 1;

lstS = unique(SD.MeasList(:,1));

% loop over unique sources
% fill in odd states and leave even states as dark states
% alternate between two wavelengths for each state

iState = 1;


for iS = 1:length(lstS)

    iSrcMod = ceil((lstS(iS)-0.1)/8); 
    iSrc = mod(lstS(iS)-1,8);

    srcram( iSrcMod, iState, 1:16 ) = bitget( round(5000 * iPower/7), 1:16, 'uint16' ); % set the power
    srcram( iSrcMod, iState, 17:20) = bitget( iSrc*2, 1:4, 'uint16' ); % select the source for wavelength 1
    srcram( iSrcMod, iState, 21) = 0;

    iState = iState + 2;

    srcram( iSrcMod, iState, 1:16 ) = bitget( round(5000 * iPower/7), 1:16, 'uint16' ); % set the power
    srcram( iSrcMod, iState, 17:20) = bitget( iSrc*2+1, 1:4, 'uint16' ); % select the source for wavelength 2
    srcram( iSrcMod, iState, 21) = 0;

    iState = iState + 2; % +2 to have a dark state
end
    
srcram(:,(iState-1):end,32) = 1; % mark sequence end


end
