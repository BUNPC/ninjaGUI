
function reportDarkLevel( SD, dSig )

sPos = SD.SrcPos2D;
dPos = SD.DetPos2D;
ml = SD.MeasList;

%%
tic
figure(2)
clf
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
    icm = max(min(ceil(10*log10(abs(dSig(lst(iML))))),64),1);
    set(hp,'color',cm(icm,:));
end

title( sprintf('Dark Level Report') )

hold off

h = colorbar();
set(h,'Ticks',[0 0.16 0.32 0.48 0.64 0.8 0.96])
set(h,'TickLabels',{'0','1','2','3','4','5','6'})

toc

