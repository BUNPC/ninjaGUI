function convertBintoSnirfv3_plotCrossTalk(SD, dataCrosstalk, lst1, iSubplot, strTitle, hf )

nS = size(SD.SrcPos3D,1);
nD = size(SD.DetPos3D,1);
ml = SD.MeasList;


figure(hf)
set(gcf,'color',[1 1 1])

subplot(2,2,iSubplot)
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
    cmIdx = ceil( (max(min(log10(dataCrosstalk(lst1(iML))),0),-3)+3)/0.1 + eps );
%    set(hl,'color', cm(cmIdx,:) )
    if cmIdx<2
        set(hl,'linewidth',0.25)
        set(hl,'color','g')
    elseif cmIdx<11
        set(hl,'linewidth',2)
        set(hl,'color','g')
    elseif cmIdx<21
        set(hl,'linewidth',2)
        set(hl,'color',[1 0.7 0])
    else        
        set(hl,'linewidth',2)
        set(hl,'color','r')
    end
end
hold off
axis image
axis off
title( strTitle )
colormap([0 1 0; 1 0.7 0; 1 0 0])
hc=colorbar();
set(hc,'ticks',[0 0.33 0.66 1]);
set(hc,'ticklabels',[{'-3'},{'-2'},{'-1'},{'0'}])
set(gca,'fontsize',16)