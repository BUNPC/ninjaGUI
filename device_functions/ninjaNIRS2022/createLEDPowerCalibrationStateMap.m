function stateMap = createLEDPowerCalibrationStateMap( SD, iPower )


stateMap= zeros(1024,32);

lstS = unique(SD.MeasList(:,1));

% loop over unique sources
% fill in odd states and leave even states as dark states
% alternate between two wavelengths for each state

iState = 1;

for iS = 1:length(lstS)
    
    % ODD wavelength
%    for iPower = 1:7
        stateMap(iState, [1:3] ) = bitget( mod(lstS(iS)-1,8), 1:3 ); % Src Row Select
        stateMap(iState, (ceil((lstS(iS)-0.1)/8)-1)*2+5 ) = 1;  %Src Col Select. Need ODD / even for wavelengths
        stateMap(iState,19:21) = bitget(iPower,1:3);% power level med
%        iState = iState + 1;
%    end

    iState = iState + 2; %  dark state

    % EVEN wavelength
%    for iPower = 1:7
        stateMap(iState, [1:3] ) = bitget( mod(lstS(iS)-1,8), 1:3 ); % Src Row Select
        stateMap(iState, (ceil((lstS(iS)-0.1)/8)-1)*2+6 ) = 1;  %Src Col Select. Need odd / EVEN for wavelengths
        stateMap(iState,19:21) = bitget(iPower,1:3); % power level med
%        iState = iState + 1;
%    end

    iState = iState + 2; %  dark state
end

stateMap((iState-1):end,27) = 1; % mark sequence end

end
