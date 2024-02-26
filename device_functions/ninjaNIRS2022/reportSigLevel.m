
function reportSigLevel( app, flagCalibratePowerLevel )

if ~exist('flagCalibratePowerLevel')
    flagCalibratePowerLevel = 0;
end

flagMakeGUI = 0;
if ~isfield(app.deviceInformation,'figReportSigLevel')
    fig = uifigure;
    set(fig,'position',[50 50 880 800])    
    app.deviceInformation.figReportSigLevel = fig;
    flagMakeGUI = 1;
else
    fig = app.deviceInformation.figReportSigLevel;
end
if ~isvalid(fig)
    fig = uifigure;
    set(fig,'position',[50 50 880 800])
    app.deviceInformation.figReportSigLevel = fig;
    flagMakeGUI = 1;
end

if flagMakeGUI
    bg = uibuttongroup(fig,'Position',[500 665 170 115]);
    tb1 = uitogglebutton(bg,'Position',[10 75 150 22],'text','Signal Level Adjustment','value',0);
    tb2 = uitogglebutton(bg,'Position',[10 45 150 22],'text','Power Level Calibration','value',0);
    tb3 = uitogglebutton(bg,'Position',[10 15 150 22],'text','RETURN to ninjaGUI','value',0);
    bgh = get(bg,'children');
    set(bg,'userdata','bg');

    txa_pow = uitextarea(fig,'position',[680 665 190 50],'value','');
    set(txa_pow,'horizontalalignment','center','fontcolor','r','fontweight','bold')
    set(txa_pow,'userdata','txa_pow');

    cb = uicheckbox(fig,'position',[680 725 190 20],'text','Spatial Multiplexing','value',1);
    acc_stat = uitextarea(fig,'position',[680 755 190 40]);

%    str = sprintf('{''line 1'';''line 2'';''line 3''}');
%    txa = eval( sprintf('uitextarea(fig,''position'',[500 300 180 350],''value'',%s);',str) );
    txa = uitextarea(fig,'position',[500 300 180 350]);
    set(txa,'horizontalalignment','center','fontcolor','r','fontweight','bold','fontsize',20)
    set(txa,'userdata','txa');

%    str = sprintf('{''line 1'';''line 2'';''line 3''}');
%    txa_det = eval( sprintf('uitextarea(fig,''position'',[690 300 180 350],''value'',%s);',str) );
    txa_det = uitextarea(fig,'position',[690 300 180 350]);
    set(txa_det,'horizontalalignment','center','fontcolor','b','fontweight','bold','fontsize',20)
    set(txa_det,'userdata','txa_det');

    ax = axes(fig,'units','pixels');
    set(ax,'Position',[10 300 480 480])
    set(ax,'xtick',[])
    set(ax,'ytick',[])
    axis(ax,'image');
    set(ax,'userdata','ax')

    ax1 = axes(fig,'units','pixels');
    set(ax1,'Position',[10 20 280 270])
    set(ax1,'xtick',[])
    set(ax1,'ytick',[])
    axis(ax1,'image');
    set(ax1,'userdata','ax1')

    ax2 = axes(fig,'units','pixels');
    set(ax2,'Position',[300 20 280 270])
    set(ax2,'xtick',[])
    set(ax2,'ytick',[])
    axis(ax2,'image');
    set(ax2,'userdata','ax2')

    ax3 = axes(fig,'units','pixels');
    set(ax3,'Position',[620 20 250 270])
    set(ax3,'xtick',[])
    set(ax3,'ytick',[])
    axis(ax3,'image');
    set(ax3,'userdata','ax3')

    app.deviceInformation.handlesReportSigLevel.bg = bg;
    app.deviceInformation.handlesReportSigLevel.txa_pow = txa_pow;
    app.deviceInformation.handlesReportSigLevel.txa = txa;
    app.deviceInformation.handlesReportSigLevel.txa_det = txa_det;
    app.deviceInformation.handlesReportSigLevel.ax = ax;
    app.deviceInformation.handlesReportSigLevel.ax1 = ax1;
    app.deviceInformation.handlesReportSigLevel.ax2 = ax2;
    app.deviceInformation.handlesReportSigLevel.ax3 = ax3;
    app.deviceInformation.handlesReportSigLevel.cb = cb;
    app.deviceInformation.handlesReportSigLevel.cb = acc_stat;
else
    bg = app.deviceInformation.handlesReportSigLevel.bg;
    txa_pow = app.deviceInformation.handlesReportSigLevel.txa_pow;
    txa = app.deviceInformation.handlesReportSigLevel.txa;
    txa_det = app.deviceInformation.handlesReportSigLevel.txa_det;
    ax = app.deviceInformation.handlesReportSigLevel.ax;
    ax1 = app.deviceInformation.handlesReportSigLevel.ax1;
    ax2 = app.deviceInformation.handlesReportSigLevel.ax2;
    ax3 = app.deviceInformation.handlesReportSigLevel.ax3;
    cb = app.deviceInformation.handlesReportSigLevel.cb;
    acc_stat = app.deviceInformation.handlesReportSigLevel.acc_stat;
    
%     h = get(fig, 'children');
%     for ii=1:length(h)
%         eval( sprintf('%s = h(%d);',get(h(ii),'userdata'),ii));
%     end
    
    bgh = get(bg,'children');
    tb3 = bgh(1);
    tb2 = bgh(2);
    tb1 = bgh(3);
    set(bgh,'visible','on')    
    axes(ax)
    drawnow
end

% check accelerometer status
if app.deviceInformation.stat.acc_active==1
    set(acc_stat,'value','Accelerometer CONNECTED','fontcolor','g','horizontalalignment','center');
else
    set(acc_stat,'value','Accelerometer NOT CONNECTED','fontcolor','r','horizontalalignment','center');
end

if flagCalibratePowerLevel==0
    set(tb1,'value',0)
    set(tb2,'value',0)
    set(tb3,'value',1)
    set( txa_pow,'value','Please select a radio button to the left');
    while get(tb1,'value')==0 && get(tb2,'value')==0 
        pause(0.1)
    end
    set( txa_pow,'value','');
    if get(tb2,'value')==1
        flagCalibratePowerLevel=1;
    end

end
if flagCalibratePowerLevel==1
    set(tb2,'value',1)
    hAxes.ax1 = ax1;
    hAxes.ax2 = ax2;
    hAxes.ax3 = ax3;
    hAxes.cb = cb;
    hAxes.txa_pow = txa_pow;
    set(app.togglebuttonStartStop,'enable','off')
    LEDPowerCalibration( app, hAxes )
    drawnow
    set(tb1,'value',1)
end


% 
% while ~get(tb3,'value')
%     pause(0.3)
%     axes(ax)
%     drawnow
% end
% 
% set(bgh,'visible','off')    
% set(txa,'value','')
% 
% return



SD = app.nSD;
sPos = SD.SrcPos2D;
dPos = SD.DetPos2D;
ml = SD.MeasList;
nSrcs = size(sPos,1);
nDets = size(dPos,1);

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
set(app.togglebuttonStartStop,'enable','off')
app.deviceFunctions.Acquisition(app,'start');

% wait N seconds
pause(1)

cm = jet(80);
cm = cm([1:2:34 46:50],:);

lst1 = find(ml(:,4)==1);
lst2 = find(ml(:,4)==2);



while get(tb1,'value') || get(tb2,'value')

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
    nPoorSrcs = zeros(nSrcs,1);
    nPoorDets = zeros(nDets,1);
    for iML = 1:length(lstl)
        hp = plot(ax,  [sPos(ml(lstTmp1(iML),1),1) dPos(ml(lstTmp1(iML),2),1)], [sPos(ml(lstTmp1(iML),1),2) dPos(ml(lstTmp1(iML),2),2)], 'c-');
        set(hp,'linewidth',2);
        nPoorSrcs(ml(lstTmp1(iML),1)) = nPoorSrcs(ml(lstTmp1(iML),1)) + 1;
        nPoorDets(ml(lstTmp1(iML),2)) = nPoorDets(ml(lstTmp1(iML),2)) + 1;
        iCol = ceil((20*log10(max(min( min(dSig(lstTmp1(iML)),dSig(lstTmp2(iML))), 1e-2), 1e-4))+81)*size(cm,1)/41);
        set(hp,'color',cm(iCol,:))
    end

    title(ax, sprintf('#Sat=%d (%d|%d) #Poor=%d (%d|%d)', length(lsth), length(lsth1), length(lsth2), length(lstl),length(lstl1),length(lstl2) ) )

    [~,orderPoorSrcs] = sort(nPoorSrcs,'descend');
    str = '';
    for ii = 1:10
        if nPoorSrcs(orderPoorSrcs(ii))>0
            str = sprintf('%sSrc %d (%d)\n',str,orderPoorSrcs(ii),nPoorSrcs(orderPoorSrcs(ii)));
        end
    end
    set(txa,'value',str);
    [~,orderPoorDets] = sort(nPoorDets,'descend');
    str = '';
    for ii = 1:10
        if nPoorDets(orderPoorDets(ii))>0
            str = sprintf('%sDet %d (%d)\n',str,orderPoorDets(ii),nPoorDets(orderPoorDets(ii)));
        end
    end
    set(txa_det,'value',str);


    % plot optodes
%    hp=plot(ax,sPos(1,1),sPos(1,2),'r.');
    for iS = 1:size(sPos,1)
        if sum(ismember(orderPoorSrcs(1:6),iS))>0 && nPoorSrcs(iS)>1
            hp = text(ax,sPos(iS,1),sPos(iS,2),sprintf('%d',iS));
            set(hp,'color','r','fontsize',20,'fontweight','bold','horizontalalignment','center')
        else
            hp=plot(ax,sPos(iS,1),sPos(iS,2),'r.');
            set(hp,'markersize',12)
        end
    end
    for iD = 1:size(dPos,1)
        if sum(ismember(orderPoorDets(1:6),iD))>0 && nPoorDets(iD)>1
            hp = text(ax,dPos(iD,1),dPos(iD,2),sprintf('%d',iD));
            set(hp,'color','b','fontsize',20,'fontweight','bold','horizontalalignment','center')
        else
            hp=plot(ax,dPos(iD,1),dPos(iD,2),'b.');
            set(hp,'markersize',12)
        end
    end

    hold(ax,'off')
    drawnow

    % do the power level calibration
    if get(tb2,'value')
        %stop acquisition
        app.deviceFunctions.Acquisition(app,'stop');
        %close file
        fclose(fileID);
        
        hAxes.ax1 = ax1;
        hAxes.ax2 = ax2;
        hAxes.ax3 = ax3;
        hAxes.cb = cb;
        hAxes.txa_pow = txa_pow;
        LEDPowerCalibration( app, hAxes )
        drawnow
        set(tb1,'value',1)

        %switch it back
        fileID=fopen(fnameDark,'w');
        app.fstreamID=fileID;
        app.deviceInformation.subtractDark=0;
        % turn acquisition on
        app.deviceFunctions.Acquisition(app,'start');
        % wait N seconds
        pause(1)
    end

end


set(bgh,'visible','off')    
%set(txa,'value','')
    

%stop acquisition
app.deviceFunctions.Acquisition(app,'stop');
set(app.togglebuttonStartStop,'enable','on')

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
