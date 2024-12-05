function convertBintoSnirfv3_plotSigVsDistance( SD, dataSDWP, powerLevelSetting)

nS = size(SD.SrcPos3D,1);
nD = size(SD.DetPos3D,1);
rhoSDS = zeros(nS,nD);
for iS=1:nS
    posS = ones(nD,1) * SD.SrcPos3D(iS,:);
    rhoSDS(iS,:) = (sum((posS - SD.DetPos3D).^2,2).^0.5)';
end

% identify the first short separation detector
[lstSSr, lstSSc] = find(rhoSDS<12);
if ~isempty(lstSSc)
    SSd1 = min(lstSSc); % I assume 1 SS bundle for now
    for ii = 1:length(lstSSr)
        rhoSDS(lstSSr(ii),SSd1) = rhoSDS(lstSSr(ii),lstSSc(ii));
    end
    nD = SSd1;
    rhoSDS(:,SSd1+1:end) = [];
end


hf = figure(1);
alpha = 0.4;

subplot(1,3,1);

foo = dataSDWP(1:nS,1:nD,1,1);
boo = rhoSDS;
scatter1 = scatter(boo(:),log10(max(foo(:),1e-8)),'MarkerFaceColor','b','MarkerEdgeColor','none');
scatter1.MarkerFaceAlpha = alpha;
scatter1.MarkerEdgeAlpha = alpha;
hold on


foo = dataSDWP(1:nS,1:nD,2,1);
scatter2 = scatter(boo(:),log10(max(foo(:),1e-8)),'MarkerFaceColor','r','MarkerEdgeColor','none');
scatter2.MarkerFaceAlpha = alpha;
scatter2.MarkerEdgeAlpha = alpha;
hold off
set(gca,'fontsize',16)
set(gca,'xtick',[0 20 40 60 80 100])
xlabel('Distance (mm)')
ylabel('log_{10}( Signal )')
title('Low Power')
legend([num2str(SD.Lambda(1)) ' nm'], [num2str(SD.Lambda(2)) ' nm'])

xlim([0 100])
ylim([-6 0])
grid on


subplot(1,3,2);

foo = dataSDWP(1:nS,1:nD,1,2);
scatter1 = scatter(boo(:),log10(max(foo(:),1e-8)),'MarkerFaceColor','b','MarkerEdgeColor','none');
scatter1.MarkerFaceAlpha = alpha;
scatter1.MarkerEdgeAlpha = alpha;
hold on

foo = dataSDWP(1:nS,1:nD,2,2);
scatter2 = scatter(boo(:),log10(max(foo(:),1e-8)),'MarkerFaceColor','r','MarkerEdgeColor','none');
scatter2.MarkerFaceAlpha = alpha;
scatter2.MarkerEdgeAlpha = alpha;
hold off
set(gca,'fontsize',16)
set(gca,'xtick',[0 20 40 60 80 100])
xlabel('Distance (mm)')
title('High Power')

xlim([0 100])
ylim([-6 0])
grid on


set(gcf,'color',[1 1 1])


% Plot the power level settings in circle plot
ml = SD.MeasList;
lst1 = find(ml(:,4)==1);
convertBintoSnirfv3_plotPowerLevel( SD, powerLevelSetting, lst1, 3, sprintf('Power level - %d nm', SD.Lambda(1)), hf )

lst1 = find(ml(:,4)==2);
convertBintoSnirfv3_plotPowerLevel( SD, powerLevelSetting, lst1, 6, sprintf('Power level - %d nm', SD.Lambda(2)), hf )
