
function reportSigLevel( app )

flagMakeGUI = 0;
if ~isfield(app.deviceInformation,'figReportSigLevel')
    fig = uifigure;
    set(fig,'position',[0 50 560 480])
    app.deviceInformation.figReportSigLevel = fig;
    flagMakeGUI = 1;
else
    fig = app.deviceInformation.figReportSigLevel;
end
if ~isvalid(fig)
    fig = uifigure;
    set(fig,'position',[0 50 560 480])
    app.deviceInformation.figReportSigLevel = fig;
    flagMakeGUI = 1;
end

if flagMakeGUI
    bg = uibuttongroup(fig,'Position',[430 10 123 85]);
    tb1 = uitogglebutton(bg,'Position',[10 50 100 22],'text','Collecting Data','value',1);
    tb2 = uitogglebutton(bg,'Position',[10 20 100 22],'text','Stop','value',0);

    ax = axes(fig,'units','pixels');
    set(ax,'Position',[10 10 400 400])
    set(ax,'xtick',[])
    set(ax,'ytick',[])
    axis(ax,'image')
else
    h = get(fig, 'children');
    ax = h(2);
    bg = h(1);
    
    h2 = get(bg,'children');
    tb2 = h2(1);
    tb1 = h2(2);
end

set(tb1,'value',1)

SD = app.nSD;
sPos = SD.SrcPos2D;
dPos = SD.DetPos2D;
ml = SD.MeasList;
nSrcs = size(sPos,1);

thresholds = app.deviceInformation.levelRepresentation.thresholds;
threshHigh = 10^(thresholds(2)/20);
threshLow  = 10^(thresholds(1)/20);

% create and open file
fnameDark=sprintf('SigLevelCheck.bin');
fileID=fopen(fnameDark,'w');

% backup normal fID
standardfID=app.fstreamID;

%switch it by dark fID
app.fstreamID=fileID;

app.deviceInformation.subtractDark=0;

% turn acquisition on
app.deviceFunctions.Acquisition(app,'start');

% wait N seconds
pause(1)

cm = jet(80);
cm = cm([1:2:34 46:50],:);

lst1 = find(ml(:,4)==1);
lst2 = find(ml(:,4)==2);



while get(tb1,'value')

    % get data
    pause(0.3)
    [data,~,~,~,~,~,~,dataDarkTmp,B] = app.deviceFunctions.ReadBytesAvailable(app);
    dSig = squeeze(mean(data,2,'omitnan'));

%     dSig = zeros(size(ml,1),1);
%     for iML = 1:size(ml,1)
%         iS = mod(ml(iML,1)-1,8)+1;
%         iD = ml(iML,2);
%         iW = ml(iML,4);
%         dSig(iML) = dataLEDPowerCalibration(iML,iPL2);
%     end

    % PLOT SATURATED AND POOR SNR
    hold(ax,'on')
    axes(ax)
    cla(ax)
    % plot saturated channels
    lsth = find( dSig(lst1)>threshHigh | dSig(lst2)>threshHigh );
    lstl = find( dSig(lst1)<threshLow | dSig(lst2)<threshLow );

    lsth1 = find( dSig(lst1)>threshHigh );
    lstl1 = find( dSig(lst1)<threshLow );

    lsth2 = find( dSig(lst2)>threshHigh );
    lstl2 = find( dSig(lst2)<threshLow );

    lstTmp = lst1(lsth);
    for iML = 1:length(lstTmp)
        hp = plot(ax, [sPos(ml(lstTmp(iML),1),1) dPos(ml(lstTmp(iML),2),1)], [sPos(ml(lstTmp(iML),1),2) dPos(ml(lstTmp(iML),2),2)], 'r-');
        set(hp,'linewidth',2);
    end
    lstTmp1 = lst1(lstl);
    lstTmp2 = lst2(lstl);
    for iML = 1:length(lstl)
        hp = plot(ax,  [sPos(ml(lstTmp1(iML),1),1) dPos(ml(lstTmp1(iML),2),1)], [sPos(ml(lstTmp1(iML),1),2) dPos(ml(lstTmp1(iML),2),2)], 'c-');
        set(hp,'linewidth',2);
        iCol = ceil((20*log10(max(min( min(dSig(lstTmp1(iML)),dSig(lstTmp2(iML))), 1e-2), 1e-4))+81)*size(cm,1)/41);
        set(hp,'color',cm(iCol,:))
    end

    title(ax, sprintf('#Sat=%d (%d|%d) #Poor=%d (%d|%d)', length(lsth), length(lsth1), length(lsth2), length(lstl),length(lstl1),length(lstl2) ) )

    % plot optodes
    hp=plot(ax,sPos(1,1),sPos(1,2),'r.');
    for iS = 2:size(sPos,1)
        hp=plot(ax,sPos(iS,1),sPos(iS,2),'r.');
        set(hp,'markersize',12)
    end
    for iD = 1:size(dPos,1)
        hp=plot(ax,dPos(iD,1),dPos(iD,2),'b.');
        set(hp,'markersize',12)
    end

    hold(ax,'off')
    drawnow

end



    

%stop acquisition
app.deviceFunctions.Acquisition(app,'stop');

%close file
fclose(fileID);


% return fID to default
app.fstreamID=standardfID;

% return the subtract dark flag to whatever it should be
if app.SubtractdarkMenu.Checked
    app.deviceInformation.subtractDark=1;
else
    app.deviceInformation.subtractDark=0;
end


%close(fig)
