function   cw6_sdgToggleLines(hObject, eventdata, app)
%This function is called when the user clicks on one of the meausrement
%lines in the SDG window

SD = app.devinfo.SD;

idx = eventdata;

%change measListAct
h2=get(app.axesSDG,'children');  %The list of all the lines currently displayed

    lst=find(SD.MeasList(:,1)==app.devinfo.plot(idx,1) &...
        SD.MeasList(:,2)==app.devinfo.plot(idx,2));
    
    %Switch the linestyles 
    if strcmp(get(h2(idx),'linestyle'), '-')
        set(h2(idx),'linestyle','--')
        SD.MeasListAct(lst)=0;
    else
        set(h2(idx),'linestyle','-')
        SD.MeasListAct(lst)=1;
    end

    app.devinfo.SD = SD;


%Update the displays
app.funcSet.dev_plotAxesSDG(app)
app.funcSet.dev_DisplayData(app)
