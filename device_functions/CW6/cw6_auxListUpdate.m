function cw6_auxListUpdate(handles)


set(handles.popupmenuAux1,'Items',handles.devinfo.cfg.auxList)
set(handles.popupmenuAux2,'Items',handles.devinfo.cfg.auxList)
set(handles.popupmenuAux3,'Items',handles.devinfo.cfg.auxList)
set(handles.popupmenuAux4,'Items',handles.devinfo.cfg.auxList)
set(handles.popupmenuAux5,'Items',handles.devinfo.cfg.auxList)
set(handles.popupmenuAux6,'Items',handles.devinfo.cfg.auxList)
set(handles.popupmenuAux7,'Items',handles.devinfo.cfg.auxList)
set(handles.popupmenuAux8,'Items',handles.devinfo.cfg.auxList)

% set visibility of aux popup and checkbox
if ~isfield(handles.devinfo,'nAux')
    nAux = 4;
else
    nAux = handles.devinfo.nAux;
end
for ii=1:nAux
    eval( sprintf('set(handles.checkboxAux%d,''visible'',''on'');',ii) );
    eval( sprintf('set(handles.popupmenuAux%d,''visible'',''on'');',ii) );
end
for ii=(nAux+1):8
    eval( sprintf('set(handles.checkboxAux%d,''visible'',''off'');',ii) );
    eval( sprintf('set(handles.popupmenuAux%d,''visible'',''off'');',ii) );
end


if ~isfield(handles.devinfo,'SD')
    return
end

%nAux=4;

if ~isfield(handles.devinfo.SD,'auxChannels')
    for ii=1:nAux
        eval(sprintf('foo = get(handles.popupmenuAux%d,''Value'');',ii));
        %foos = handles.devinfo.cfg.auxList{foo};
        handles.devinfo.SD.auxChannels{ii} = foo;
    end
    %     foo = get(handles.popupmenuAux2,'value');
    %     foos = handles.devinfo.cfg.auxList{foo};
    %     handles.devinfo.SD.auxChannels{2} = foos;
    %
    %     foo = get(handles.popupmenuAux3,'value');
    %     foos = handles.devinfo.cfg.auxList{foo};
    %     handles.devinfo.SD.auxChannels{3} = foos;
    %
    %     foo = get(handles.popupmenuAux4,'value');
    %     foos = handles.devinfo.cfg.auxList{foo};
    %     handles.devinfo.SD.auxChannels{4} = foos;
end

%nAux=4;

flagStim = 0;
if ~isempty(handles.devinfo.SD.auxChannels)
    for ii=1:nAux
        idx = 0;
        
        if strcmpi(handles.devinfo.SD.auxChannels{ii},'Trig Stim')
            flagStim = 1;
        end
        
        for jj=1:length(handles.devinfo.cfg.auxList)
            
            if strcmpi(handles.devinfo.SD.auxChannels{ii},handles.devinfo.cfg.auxList{jj})
                idx = jj;
            end
        end
        
        eval(sprintf('set(handles.popupmenuAux%d,''Value'',handles.popupmenuAux1.Items{idx})',ii));
        %     switch ii
        %         case 1
        %             set(handles.popupmenuAux1,'value',idx)
        %         case 2
        %             set(handles.popupmenuAux2,'value',idx)
        %         case 3
        %             set(handles.popupmenuAux3,'value',idx)
        %         case 4
        %             set(handles.popupmenuAux4,'value',idx)
        %     end
    end
end

% if an aux is labeled as stim then turn off the stim mark
if flagStim
    set(handles.pushbuttonStimMark,'visible','off')
else
    set(handles.pushbuttonStimMark,'visible','on')
end

