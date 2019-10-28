function cw6_readBytesAvailable(obj,event,app)

persistent a

wpr = app.devinfo.WordsPerRecord;
rpd = app.devinfo.recordsPerDisplay;

[a, wordsRead] = fread( app.sp, app.devinfo.wordsPerDisplay, 'float' ); 
%jc 6/27/2017 drop corrupted record and record error
%handling -999 misalignment this way does not lock up program
if a(wpr)~=-999
    flushinput(app.sp);
    return;
end
f = a( app.devinfo.SD.MeasList_USBorder*ones(1,rpd) + ...
       wpr*ones(length(app.devinfo.SD.MeasList_USBorder),1)*[0:rpd-1] );
f = f(:);
recInfo = a( (wpr-1)*ones(1,rpd) + wpr*[0:rpd-1] );
rec999 = a( (wpr-1)*ones(1,rpd) + wpr*[0:rpd-1] + 1 );
lst = ([(wpr-(app.devinfo.nAux+1)):(wpr-2)])'*ones(1,rpd) + ones(app.devinfo.nAux,1)*wpr*[0:rpd-1];
aux = a( lst(:) );

t = app.devinfo.tIdx+[0:rpd-1];
app.devinfo.tIdx = app.devinfo.tIdx + app.devinfo.recordsPerDisplay;
app.devinfo.nRecords = app.devinfo.tIdx;

app.devinfo.time(app.devinfo.tPtr+[1:length(t)]) = t/app.devinfo.recordRate;
app.devinfo.tPtr = app.devinfo.tPtr + length(t);

app.devinfo.data(app.devinfo.dataPtr+[1:length(f)]) = f;
app.devinfo.dataPtr = app.devinfo.dataPtr + length(f);

app.devinfo.recInfo(app.devinfo.recInfoPtr+[1:length(recInfo)]) = recInfo;
app.devinfo.rec999(app.devinfo.recInfoPtr+[1:length(recInfo)]) = rec999;
app.devinfo.recInfoPtr = app.devinfo.recInfoPtr + length(recInfo);

app.devinfo.dataAux(app.devinfo.dataAuxPtr+[1:length(aux)]) = aux/6554;
app.devinfo.dataAuxPtr = app.devinfo.dataAuxPtr + length(aux);



if app.devinfo.RecordContinuously==1 && app.devinfo.nRecords>=app.devinfo.nRecordsMaxHW
    app.devinfo.RecordContinuously = 2;
    
    app.devinfo.filenm_num = app.devinfo.filenm_num + 1;
    filenm = sprintf('%s_%02d.nirs',app.devinfo.filenm_base,app.devinfo.filenm_num);
    app.funcSet.dev_SaveData({app.devinfo.filenm_base_path filenm 1 (app.devinfo.nRecordsMaxHW-1)},app );
    
    strMessage = sprintf('%s', filenm);
    for ii=1:length(app.devinfo.SD.MeasListMask)
        strMessage = sprintf('%s\nS%d D%d W%d   %.2f',strMessage,...
                              app.devinfo.SD.MeasList(ii,1),...
                              app.devinfo.SD.MeasList(ii,2),...
                              app.devinfo.SD.MeasList(ii,4),...
                              f(ii) );
    end
    try 
        sendmail(app.devinfo.cfg.email_recipient, app.devinfo.cfg.email_subject, strMessage);
    catch
        fprintf('\n!!!STATUS email failed to send at %s!!!\n', datestr(now, 'HH:MM:SS'));
    end
    
    filenm = sprintf('%s_%02d.nirs',app.devinfo.filenm_base,app.devinfo.filenm_num+1);
    ht = xlabel( app.devinfo.axesSDG, sprintf('Running %s',filenm) );
    set(ht,'interpreter','none')    
end

if app.devinfo.nRecords>=app.devinfo.nRecordsMax
    if app.devinfo.RecordContinuously == 0    
%         h=findobj('tag','cw6');
%         handles=guihandles(h);
        set(app.togglebuttonStartStop,'Value',0);
        cw6('togglebuttonStartStop_Callback',app.togglebuttonStartStop,[],handles); %????
        %togglebuttonStartStop_Callback(handles.togglebuttonStartStop, [], handles)
    else
        i2 = app.devinfo.nRecords;
        app.devinfo.tIdx = 0;
        app.devinfo.tPtr = 0;
        app.devinfo.dataPtr = 0;
        app.devinfo.recInfoPtr = 0;
        app.devinfo.dataAuxPtr = 0;
        app.devinfo.RecordContinuously=1;
        
        app.devinfo.filenm_num = app.devinfo.filenm_num + 1;
        filenm = sprintf('%s_%02d.nirs',app.devinfo.filenm_base,app.devinfo.filenm_num);
        app.funcSet.dev_SaveData( {app.devinfo.filenm_base_path filenm app.devinfo.nRecordsMaxHW i2} );
    
        strMessage = sprintf('%s', filenm);
        for ii=1:length(app.devinfo.SD.MeasListMask)
            strMessage = sprintf('%s\nS%d D%d W%d   %.2f',strMessage,...
                app.devinfo.SD.MeasList(ii,1),...
                app.devinfo.SD.MeasList(ii,2),...
                app.devinfo.SD.MeasList(ii,4),...
                f(ii) );
        end
        
        try
            sendmail(app.devinfo.cfg.email_recipient, app.devinfo.cfg.email_subject, strMessage);
        catch
            disp(sprintf('\n!!!STATUS email failed to send at %s!!!\n', datestr(now, 'HH:MM:SS')));
        end
        
        axes(app.devinfo.axesSDG)
        filenm = sprintf('%s_%02d.nirs',app.devinfo.filenm_base,app.devinfo.filenm_num+1);
        ht = xlabel( app.devinfo.axesSDG,sprintf('Running %s',filenm) );
        set(ht,'interpreter','none')    
    end
end




if app.devinfo.DisplayWindow==0
    return;
end


app.funcSet.dev_DisplayData(app);


% this will update SDG signal level warnings
if app.devinfo.SDGdisplayLevel
    app.funcSet.dev_plotAxesSDG(app)
end
