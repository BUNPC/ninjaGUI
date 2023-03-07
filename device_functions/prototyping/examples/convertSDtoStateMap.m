function stateMap = convertSDtoStateMap(SD)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

stateMap= zeros(1024,32);

lstS = unique(SD.MeasList(:,1));

% loop over unique sources
% fill in odd states and leave even states as dark states
% alternate between two wavelengths for each state

iState = 1;
for iS = 1:length(lstS)
    
    stateMap(iState, mod(lstS(iS)-1,8)+1 ) = 1; % Src Row Select
    stateMap(iState, (ceil((lstS(iS)-0.1)/8)-1)*2+9 ) = 1;  %Src Col Select. Need ODD / even for wavelengths
    stateMap(iState,19:21) = [0 1 0]; % power level hi
    
    iState = iState + 2; % EVEN wavelength
    stateMap(iState, mod(lstS(iS)-1,8)+1 ) = 1; % Src Row Select
    stateMap(iState, (ceil((lstS(iS)-0.1)/8)-1)*2+10 ) = 1;  %Src Col Select. Need odd / EVEN for wavelengths
    stateMap(iState,19:21) = [0 1 0]; % power level hi
    
    iState = iState + 2;
end

stateMap((iState-1):end,27) = 1; % mark sequence end

end
