function cw6_AxesSDG_buttondown(hObject, eventdata, handles)

global cw6info

if ~isfield(cw6info,'SD')
    return;
end


pos = get(handles.axesSDG,'CurrentPoint');

SD = cw6info.SD;

%find the closest optode
rmin = ( (pos(1,1)-SD.SrcPos(1,1))^2 + (pos(1,2)-SD.SrcPos(1,2))^2 )^0.5 ;
idxMin = 1;
SrcMin = 1;
for idx=1:SD.nSrcs
    ropt = ( (pos(1,1)-SD.SrcPos(idx,1))^2 + (pos(1,2)-SD.SrcPos(idx,2))^2 )^0.5 ;
    if ropt<rmin
        idxMin = idx;
        rmin = ropt;
    end
end
for idx=1:SD.nDets
    ropt = ( (pos(1,1)-SD.DetPos(idx,1))^2 + (pos(1,2)-SD.DetPos(idx,2))^2 )^0.5 ;
    if ropt<rmin
        idxMin = idx;
        SrcMin = 0;
        rmin = ropt;
    end
end

% copied from cw6_plotLst
%idxLambda = cw6info.displayLambda;
if SrcMin
    lst1 = find( SD.MeasList(:,1)==idxMin & SD.MeasList(:,4)==1 );
    lst2 = find( SD.MeasList(:,1)==idxMin & SD.MeasList(:,4)==2 );
else
    lst1 = find( SD.MeasList(:,2)==idxMin & SD.MeasList(:,4)==1 );
    lst2 = find( SD.MeasList(:,2)==idxMin & SD.MeasList(:,4)==2 );
end


% modify the global variables
cw6info.plotLst_SrcMin = SrcMin;
cw6info.plotLst_idxMin = idxMin;

% code from this functio copied below
%cw6_plotLst()

if SrcMin
    cw6info.plotLst1 = lst1;
    cw6info.plotLst2 = lst2;
    cw6info.plot = [idxMin*ones(length(lst),1) SD.MeasList(lst,2)];
else
    cw6info.plotLst1 = lst1;
    cw6info.plotLst2 = lst2;
    cw6info.plot = [SD.MeasList(lst,1) idxMin*ones(length(lst),1)];
end





cw6_plotAxesSDG(handles)

if max(cw6info.time)>0
    cw6_DisplayData()
end

