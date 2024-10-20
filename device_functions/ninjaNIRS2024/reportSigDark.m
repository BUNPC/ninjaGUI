
function reportSigDark( SD, dSig, dDark, B_Dark, thresholds, hAxes )

sPos = SD.SrcPos2D;
dPos = SD.DetPos2D;
ml = SD.MeasList;




% PLOT DARK

axes(hAxes.ax2)
cm = jet(64);

% plot optodes
hp=plot(hAxes.ax2,sPos(1,1),sPos(1,2),'r.');
hold(hAxes.ax2,'on')
for iS = 2:size(sPos,1)
    hp=plot(hAxes.ax2,sPos(iS,1),sPos(iS,2),'r.');
end
for iD = 1:size(dPos,1)
    hp=plot(hAxes.ax2,dPos(iD,1),dPos(iD,2),'b.');
end

% plot channel dark levels
lst = find(ml(:,4)==1);

for iML = 1:length(lst)
    hp = plot(hAxes.ax2, [sPos(ml(lst(iML),1),1) dPos(ml(lst(iML),2),1)], [sPos(ml(lst(iML),1),2) dPos(ml(lst(iML),2),2)], 'k-');
    icm = max(min(ceil(10*log10(abs(dDark(lst(iML))))),0),-63) + 64;
    set(hp,'color',cm(icm,:));
end

title(hAxes.ax2, sprintf('Dark Level Report') )

axis(hAxes.ax2,'image')
set(hAxes.ax2,'yticklabel',{})
set(hAxes.ax2,'xticklabel',{})
hold(hAxes.ax2,'off')

colormap(hAxes.ax2,jet(64))
h = colorbar(hAxes.ax2);
set(h,'Ticks',[0 0.16 0.32 0.48 0.64 0.8 0.96]+0.04)
set(h,'TickLabels',{'-6','-5','-4','-3','-2','-1','0'})





% plot PSD of dark signal
B = permute(B_Dark,[3 1 2]);
B = reshape(B,[size(B,1)*size(B,2) size(B,3)]);

ysum = [];
n = 0;
for ii=1:size(B,2)
    d = NN22_interpNAN(B(:,ii));

    if 1 %mean(d)<1e6
        [y,f]=(pwelch(d,[],[],[],800));

        if isempty(ysum)
            ysum = sqrt(y);
        else
            ysum = ysum + sqrt(y);
        end
        n=n+1;
    end
end
ysum = ysum / n;

%subplot(1,3,3)
axes(hAxes.ax3)
semilogy(hAxes.ax3,f,ysum)
xlabel(hAxes.ax3,'Freq (Hz)')



