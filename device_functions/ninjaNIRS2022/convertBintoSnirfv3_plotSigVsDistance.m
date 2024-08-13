function convertBintoSnirfv3_plotSigVsDistance( SD, dataSDWP)

nS = size(SD.SrcPos3D,1);
nD = size(SD.DetPos3D,1);
rhoSDS = zeros(nS,nD);
for iS=1:nS
    posS = ones(nD,1) * SD.SrcPos3D(iS,:);
    rhoSDS(iS,:) = (sum((posS - SD.DetPos3D).^2,2).^0.5)';
end


figure
alpha = 0.4;

subplot(1,2,1);

foo = dataSDWP(:,:,1,1);
boo = rhoSDS;
scatter1 = scatter(boo(:),log10(max(foo(:),1e-8)),'MarkerFaceColor','b','MarkerEdgeColor','none');
scatter1.MarkerFaceAlpha = alpha;
scatter1.MarkerEdgeAlpha = alpha;
hold on


foo = dataSDWP(:,:,2,1);
scatter2 = scatter(boo(:),log10(max(foo(:),1e-8)),'MarkerFaceColor','r','MarkerEdgeColor','none');
scatter2.MarkerFaceAlpha = alpha;
scatter2.MarkerEdgeAlpha = alpha;
hold off
set(gca,'fontsize',16)
set(gca,'xtick',[0 20 40 60 80 100])
xlabel('Distance (mm)')
ylabel('log_{10}( Signal )')
title('Low Power ~ 0.7 mW')

xlim([0 100])
ylim([-6 0])
grid on


subplot(1,2,2);

foo = dataSDWP(:,:,1,2);
scatter1 = scatter(boo(:),log10(max(foo(:),1e-8)),'MarkerFaceColor','b','MarkerEdgeColor','none');
scatter1.MarkerFaceAlpha = alpha;
scatter1.MarkerEdgeAlpha = alpha;
hold on

foo = dataSDWP(:,:,2,2);
scatter2 = scatter(boo(:),log10(max(foo(:),1e-8)),'MarkerFaceColor','r','MarkerEdgeColor','none');
scatter2.MarkerFaceAlpha = alpha;
scatter2.MarkerEdgeAlpha = alpha;
hold off
set(gca,'fontsize',16)
set(gca,'xtick',[0 20 40 60 80 100])
xlabel('Distance (mm)')
title('High Power ~ 70 mW')

xlim([0 100])
ylim([-6 0])
grid on


set(gcf,'color',[1 1 1])