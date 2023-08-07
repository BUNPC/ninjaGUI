
function reportSigDark( SD, dSig, dDark, B_Dark, thresholds )

sPos = SD.SrcPos2D;
dPos = SD.DetPos2D;
ml = SD.MeasList;

threshHigh = 10^(thresholds(2) / 20);
threshLow = 10^(thresholds(1) / 20);

%%
tic
figure(1)
clf

% PLOT SATURATED AND POOR SNR
    subplot(1,3,1)

    % plot optodes
    hp=plot(sPos(1,1),sPos(1,2),'r.');
    hold on
    for iS = 2:size(sPos,1)
        hp=plot(sPos(iS,1),sPos(iS,2),'r.');
    end
    for iD = 1:size(dPos,1)
        hp=plot(dPos(iD,1),dPos(iD,2),'b.');
    end

    % plot saturated channels
    lst1 = find(ml(:,4)==1);
    lst2 = find(ml(:,4)==2);
    lsth = find( dSig(lst1)>threshHigh | dSig(lst2)>threshHigh );
    lstl = find( dSig(lst1)<threshLow | dSig(lst2)<threshLow );

    lsth1 = find( dSig(lst1)>threshHigh );
    lstl1 = find( dSig(lst1)<threshLow );

    lsth2 = find( dSig(lst2)>threshHigh );
    lstl2 = find( dSig(lst2)<threshLow );

    for iML = 1:length(lsth)
        hp = plot( [sPos(ml(lsth(iML),1),1) dPos(ml(lsth(iML),2),1)], [sPos(ml(lsth(iML),1),2) dPos(ml(lsth(iML),2),2)], 'r-');
    end
    for iML = 1:length(lstl)
        hp = plot( [sPos(ml(lstl(iML),1),1) dPos(ml(lstl(iML),2),1)], [sPos(ml(lstl(iML),1),2) dPos(ml(lstl(iML),2),2)], 'c-');
    end

    title( sprintf('#Sat=%d (%d|%d) #Poor=%d (%d|%d)', length(lsth), length(lsth1), length(lsth2), length(lstl),length(lstl1),length(lstl2) ) )
    axis image
    set(gca,'yticklabel',{})
    set(gca,'xticklabel',{})

    hold off




    
% PLOT DARK
subplot(1,3,2)
cm = jet(64);


% plot optodes
hp=plot(sPos(1,1),sPos(1,2),'r.');
hold on
for iS = 2:size(sPos,1)
    hp=plot(sPos(iS,1),sPos(iS,2),'r.');
end
for iD = 1:size(dPos,1)
    hp=plot(dPos(iD,1),dPos(iD,2),'b.');
end

% plot channel dark levels
lst = find(ml(:,4)==1);

for iML = 1:length(lst)
    hp = plot( [sPos(ml(lst(iML),1),1) dPos(ml(lst(iML),2),1)], [sPos(ml(lst(iML),1),2) dPos(ml(lst(iML),2),2)], 'k-');
    icm = max(min(ceil(10*log10(abs(dDark(lst(iML))))),0),-63) + 64;
    set(hp,'color',cm(icm,:));
end

title( sprintf('Dark Level Report') )

axis image
set(gca,'yticklabel',{})
set(gca,'xticklabel',{})
hold off

colormap(jet(64))
h = colorbar();
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

subplot(1,3,3)
semilogy(f,ysum)
xlabel('Freq (Hz)')


toc

