function cw6_plotLst()
global cw6info

SrcMin = cw6info.plotLst_SrcMin;
idxMin = cw6info.plotLst_idxMin;
SD = cw6info.SD;

%idxLambda = cw6info.displayLambda;

if SrcMin
    lst1 = find( SD.MeasList(:,1)==idxMin & SD.MeasList(:,4)==1 );
    cw6info.plotLst1 = lst1;
    lst2 = find( SD.MeasList(:,1)==idxMin & SD.MeasList(:,4)==2 );
    cw6info.plotLst2 = lst2;
    cw6info.plot = [idxMin*ones(length(lst1),1) SD.MeasList(lst1,2)];
else
    lst1 = find( SD.MeasList(:,2)==idxMin & SD.MeasList(:,4)==1 );
    cw6info.plotLst1 = lst1;
    lst2 = find( SD.MeasList(:,2)==idxMin & SD.MeasList(:,4)==2 );
    cw6info.plotLst2 = lst2;
    cw6info.plot = [SD.MeasList(lst2,1) idxMin*ones(length(lst2),1)];
end
