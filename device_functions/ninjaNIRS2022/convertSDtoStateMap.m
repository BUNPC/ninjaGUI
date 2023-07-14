function stateMap = convertSDtoStateMap(SD)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

stateMap= zeros(1024,32);


% loop over unique sources
% fill in odd states and leave even states as dark states
% alternate between two wavelengths for each state

if 0
    % used for cycling through each source one at a time

    lstS = unique(SD.MeasList(:,1));

    iState = 1;
    for iS = 1:length(lstS)

        % [1:3] src row select (binary encoding); [4:8] reserved; [9:16] src col select
        % [17:18] reserved; [19:21] power selection (binary encoding)
        % [22:26] reserved; [27] end of state series marker 
        % Power levels: 0-0, 1-1, 2-2, 3-4, 4-8.3, 5-25, 6-44, 7-76
        stateMap(iState, [1:3] ) = bitget( mod(lstS(iS)-1,8), 1:3 ); % Src Row Select
        stateMap(iState, (ceil((lstS(iS)-0.1)/8)-1)*2+9 ) = 1;  %Src Col Select. Need ODD / even for wavelengths
        stateMap(iState,19:21) = bitget(4,1:3); % power level med; high '7' is [1 1 1] and low '1' is [1 0 0]

        iState = iState + 2; % EVEN wavelength
        stateMap(iState, [1:3] ) = bitget( mod(lstS(iS)-1,8), 1:3 ); % Src Row Select
        stateMap(iState, (ceil((lstS(iS)-0.1)/8)-1)*2+10 ) = 1;  %Src Col Select. Need ODD / even for wavelengths
        stateMap(iState,19:21) = bitget(4,1:3); % power level high '7' is [1 1 1] and low '1' is [1 0 0]
        
        % OLD
%         stateMap(iState, mod(lstS(iS)-1,8)+1 ) = 1; % Src Row Select
%         stateMap(iState, (ceil((lstS(iS)-0.1)/8)-1)*2+9 ) = 1;  %Src Col Select. Need ODD / even for wavelengths
%         stateMap(iState,19:21) = [0 1 0]; % power level med; high is [1 0 0] and low is [0 0 1]
% 
%         iState = iState + 2; % EVEN wavelength
%         stateMap(iState, mod(lstS(iS)-1,8)+1 ) = 1; % Src Row Select
%         stateMap(iState, (ceil((lstS(iS)-0.1)/8)-1)*2+10 ) = 1;  %Src Col Select. Need odd / EVEN for wavelengths
%         stateMap(iState,19:21) = [0 1 0]; % power level med
% 
        iState = iState + 2;
    end

    stateMap((iState-1):end,27) = 1; % mark sequence end

elseif 1
    % spatially multiplex
    nSrcModules = 3;

        % [1:3] src row select (binary encoding); [4:8] reserved; [9:16] src col select
        % [17:18] reserved; [19:21] power selection (binary encoding)
        % [22:26] reserved; [27] end of state series marker 
        % Power levels: 0-0, 1-1, 2-2, 3-4, 4-8.3, 5-25, 6-44, 7-76

    iState = 1;
    for iS = 1:8
%        stateMap(iState, iS ) = 1;%bitget(iS,1:3); % Src Row Select
        stateMap(iState, [1:3] ) = bitget(iS,1:3); % Src Row Select
        stateMap(iState, 7+[1:nSrcModules]*2 ) = 1;  %Src Col Select. Need ODD / even for wavelengths
%        stateMap(iState,19:21) = [0 1 0];% bitget(2,1:3); % power level high '7' is [1 1 1] and low '1' is [1 0 0]
        stateMap(iState,19:21) = bitget(1,1:3); % power level high '7' is [1 1 1] and low '1' is [1 0 0]

        iState = iState + 1; % EVEN wavelength
%        stateMap(iState, iS ) = 1;%bitget(iS,1:3); % Src Row Select
        stateMap(iState, [1:3] ) = bitget(iS,1:3); % Src Row Select
        stateMap(iState, 8+[1:nSrcModules]*2 ) = 1;  %Src Col Select. Need ODD / even for wavelengths
%        stateMap(iState,19:21) = [0 1 0];% bitget(2,1:3); % power level high '7' is [1 1 1] and low '1' is [1 0 0]
        stateMap(iState,19:21) = bitget(1,1:3); % power level high '7' is [1 1 1] and low '1' is [1 0 0]

        iState = iState + 2;
    end

    stateMap((iState-1):end,27) = 1; % mark sequence end

end


end
