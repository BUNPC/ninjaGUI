
function convertBintoSnirfv3_crossTalk( stateMap, dataSDWP_LowHigh )


% CROSS TALK
ml = stateMap.nSD.MeasList;
srcModuleGroups = stateMap.devInfo.srcModuleGroups;

dataCrosstalk = zeros(size(ml,1),1);
dataCrosstalkLow = zeros(size(ml,1),1);

for iML = 1:size(ml,1)
    iS = ml(iML,1);
    iD = ml(iML,2);
    iW = ml(iML,4);

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

    % High power
    data = dataSDWP_LowHigh(iSrc:8:end,iD,iW,2);
    
    if data(iSrcModule)>1e-2
        data = data / data(iSrcModule); % normalize to get cross-talk from other source modules
        data(iSrcModule) = 0; % no cross talk from itself
        data = data(stateMap.devInfo.srcModuleGroups{iSg}); % only consider modules within the group for high power
        dataCrosstalk(iML) = sum(abs(data)); % sum up cross talk from other modules. FIXME - abs or not... I don't like that I have negative numbers... but those are low signals anyways
    end

    % Low power
    data = dataSDWP_LowHigh(iSrc:8:end,iD,iW,1);
    if data(iSrcModule)>1e-2
        data = data / data(iSrcModule); % normalize to get cross-talk from other source modules
        data(iSrcModule) = 0; % no cross talk from itself
        dataCrosstalkLow(iML) = sum(abs(data)); % sum up cross talk from other modules. FIXME - abs or not... I don't like that I have negative numbers... but those are low signals anyways
    end
end


% Plot the results in data matrix form
figure
set(gcf,'color',[1 1 1])

subplot(2,2,1)
imagesc( log10(abs(dataSDWP_LowHigh(:,:,1,1))), [-6 0] )
ylabel("Source")
title( sprintf('LOW Power, %d nm', stateMap.nSD.lambda(1)) )

subplot(2,2,2)
imagesc( log10(abs(dataSDWP_LowHigh(:,:,1,2))), [-6 0] )
title( sprintf('HIGH Power, %d nm', stateMap.nSD.lambda(1)) )

subplot(2,2,3)
imagesc( log10(abs(dataSDWP_LowHigh(:,:,2,1))), [-6 0] )
ylabel("Source")
title( sprintf('LOW Power, %d nm', stateMap.nSD.lambda(2)) )
xlabel('Detector')

subplot(2,2,4)
imagesc( log10(abs(dataSDWP_LowHigh(:,:,2,2))), [-6 0] )
title( sprintf('HIGH Power, %d nm', stateMap.nSD.lambda(2)) )
xlabel('Detector')




% Plot the results in circle plot
hf = figure;

lst1 = find(ml(:,4)==1);
convertBintoSnirfv3_plotCrossTalk( stateMap.nSD, dataCrosstalkLow, lst1, 1, sprintf('Low Power %d nm', stateMap.nSD.lambda(1)), hf )

lst1 = find(ml(:,4)==1);
convertBintoSnirfv3_plotCrossTalk( stateMap.nSD, dataCrosstalk, lst1, 2, sprintf('High Power %d nm', stateMap.nSD.lambda(1)), hf )

lst1 = find(ml(:,4)==2);
convertBintoSnirfv3_plotCrossTalk( stateMap.nSD, dataCrosstalkLow, lst1, 3, sprintf('Low Power %d nm', stateMap.nSD.lambda(2)), hf )

lst1 = find(ml(:,4)==2);
convertBintoSnirfv3_plotCrossTalk( stateMap.nSD, dataCrosstalk, lst1, 4, sprintf('High Power %d nm', stateMap.nSD.lambda(2)), hf )


