
function reportSigLevel( app )

fig = uifigure;

bg = uibuttongroup(fig,'Position',[137 113 123 85]);
tb1 = uitogglebutton(bg,'Position',[10 50 100 22],'text','Collecting Data','value',1);
tb2 = uitogglebutton(bg,'Position',[10 20 100 22],'text','Stop','value',0);


SD = app.nSD;
sPos = SD.SrcPos2D;
dPos = SD.DetPos2D;
ml = SD.MeasList;


% create and open file
fnameDark=sprintf('SigLevelCheck.bin');
fileID=fopen(fnameDark,'w');

% backup normal fID
standardfID=app.fstreamID;

%switch it by dark fID
app.fstreamID=fileID;

% turn acquisition on
app.deviceFunctions.Acquisition(app,'start');

% wait N seconds
pause(1)


while get(tb1,'value')

    [data,~,~,~,~,~,~,dataDarkTmp,B] = app.deviceFunctions.ReadBytesAvailable(app);

    % PLOT SATURATED AND POOR SNR
    subplot(1,1,1)

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
    lsth = find(dSig>6e6);
    lst1h = lsth( find(ml(lsth,4)==1) );

    lstl = find(dSig<4e4);
    lst1l = lstl( find(ml(lstl,4)==1) );

    for iML = 1:length(lst1h)
        hp = plot( [sPos(ml(lst1h(iML),1),1) dPos(ml(lst1h(iML),2),1)], [sPos(ml(lst1h(iML),1),2) dPos(ml(lst1h(iML),2),2)], 'r-');
    end
    for iML = 1:length(lst1l)
        hp = plot( [sPos(ml(lst1l(iML),1),1) dPos(ml(lst1l(iML),2),1)], [sPos(ml(lst1l(iML),1),2) dPos(ml(lst1l(iML),2),2)], 'c-');
    end

    title( sprintf('%dnm - #Sat=%d  #Poor=%d', SD.Lambda(iWav), length(lst1h), length(lst1l) ) )

    hold off




    

    %stop acquisition
    app.deviceFunctions.Acquisition(app,'stop');

close(fig)
