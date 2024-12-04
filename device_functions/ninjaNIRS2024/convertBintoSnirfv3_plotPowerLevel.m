function convertBintoSnirfv3_plotPowerLevel(SD, powerLevelSetting, lst1, iSubplot, strTitle, hf )

nS = size(SD.SrcPos3D,1);
nD = size(SD.DetPos3D,1);
ml = SD.MeasList;

cm = jet(7);
colormap(cm)

figure(hf)
set(gcf,'color',[1 1 1])

subplot(1,2,iSubplot)
for iS=1:nS
    plot(SD.SrcPos2D(iS,1),SD.SrcPos2D(iS,2),'r.','markersize',20);
    hold on
end
for iD=1:nD
    plot(SD.DetPos2D(iD,1),SD.DetPos2D(iD,2),'b.','markersize',20);
end
for iML = 1:length(lst1)
    iS = ml(lst1(iML),1);
    iD = ml(lst1(iML),2);
    iW = ml(lst1(iML),4);
    ps = SD.SrcPos2D(iS,:);
    pd = SD.DetPos2D(iD,:);
    hl = plot( [ps(1) pd(1)], [ps(2) pd(2)], '-');
    set(hl,'linewidth',2)
    cmIdx = powerLevelSetting(lst1(iML));
    set(hl,'color', cm(cmIdx,:) )
end
hold off
axis image
axis off
title( strTitle )
hc=colorbar();
h = 1/7;
set(hc,'ticks',[h/2 5*h/2 9*h/2 13*h/2]);
set(hc,'ticklabels',[{'1'},{'3'},{'5'},{'7'}])
set(gca,'fontsize',16)