function cw6_SaveData(eventdata,app)



if ~iscell(eventdata)%RCD 01/19/2017 replaced isempty w/iscell
    [filenm, pathnm] = uiputfile( '*.nirs', 'Save Data' );
    iRecords0 = 1;
    iRecords1 = app.devinfo.nRecords;
else
    filenm = eventdata{2};
    pathnm = sprintf('%s\\%s\\',cd,eventdata{1});
    if length(eventdata)==2
        iRecords0 = 1;
        iRecords1 = app.devinfo.nRecords;
    else
        iRecords0 = eventdata{3};
        iRecords1 = eventdata{4};
    end
end

if filenm==0
    return;
end

SD = app.devinfo.SD;
ml = app.devinfo.SD.MeasList;
nRecords = app.devinfo.nRecords;

if ndims(app.devinfo.data)==2
    d = app.devinfo.data(1:size(ml,1),iRecords0:iRecords1)';
    d = 10.^(d/20);
else
    d = app.devinfo.data(1:size(ml,1),:,iRecords0:iRecords1);
end
t = app.devinfo.time(iRecords0:iRecords1)';

if isfield(app.devinfo,'dataStd')
    if ndims(app.devinfo.data)==2
        dStd = app.devinfo.dataStd(1:size(ml,1),iRecords0:iRecords1)';
    else
        dStd = app.devinfo.dataStd(1:size(ml,1),:,iRecords0:iRecords1);
    end
else
    dStd = [];
end

if isfield(app.devinfo,'dataAux');
    aux = app.devinfo.dataAux(:,iRecords0:iRecords1)';
else
    aux = [];
end

% get stim vector s
% use stim mark (do not consider aux 'trig stim' as s)
%if ~isfield(app.devinfo,'nAux')
%    nAux = 4;
%else
%    nAux = app.devinfo.nAux;
%end
%flagStim = 0;
%for iAux=1:nAux
%    if strcmpi(app.devinfo.SD.auxChannels{iAux},'Trig Stim')
%        flagStim = iAux;
%    end
%end
%if flagStim==0
    if isfield(app.devinfo,'stimMark')
        s = app.devinfo.stimMark(iRecords0:iRecords1)';
    else
        s = zeros(iRecords1-iRecords0+1,1);
    end
%else
%    s = aux(:,flagStim);
%end


if app.devinfo.SrcStateEnable == 1
    tdml = zeros(size(ml,1),iRecords1-iRecords0+1);
    
    mlmap = zeros(size(ml,1),3);
    for ii=1:3
        lsr = dec2bin(app.devinfo.SrcStateLsrOn(ii),16);
        lsr = lsr(end:-1:1);
        lst = find(lsr=='1');
        for jj=1:length(lst)
            [iWavelength,iSrc] = find(SD.SrcMap==lst(jj));
            iML = find(ml(:,1)==iSrc & ml(:,4)==iWavelength);
            mlmap(iML,ii) = 1;
        end
    end
    
    for ii=1:(iRecords1-iRecords0+1)
        foos = dec2bin(hex2dec(num2hex(app.devinfo.recInfo(iRecords0+ii-1))));
        foos2 = dec2hex(bin2dec(foos(2:33)));
        tdml(:,ii) = mlmap(:,str2double(foos2(2)));
    end
else
    tdml = ones(size(ml,1),iRecords1-iRecords0+1);
end

%get system information to save it to the data file
systemInfo.lasersOn = app.devinfo.lasersOn;
systemInfo.gain = app.devinfo.gain;
systemInfo.SDfilepath = app.devinfo.SDfilepath;
systemInfo.SDfilenm = app.devinfo.SDfilenm;
if isfield(app.devinfo,'gainStates')
    systemInfo.gainStates = app.devinfo.gainStates;
    systemInfo.laserStates = app.devinfo.laserStates;
    systemInfo.attenLevels = app.devinfo.attenLevels;
end
if isfield(app.devinfo,'recInfo')
    systemInfo.recInfo = app.devinfo.recInfo(iRecords0:iRecords1);
    systemInfo.rec999 = app.devinfo.rec999(iRecords0:iRecords1);
end
systemInfo.SrcStateLsrOn = app.devinfo.SrcStateLsrOn;
if isfield(app.devinfo,'SrcStateDwell')
    systemInfo.SrcStateDwell = app.devinfo.SrcStateDwell;
end
systemInfo.SrcStateEnable = app.devinfo.SrcStateEnable;
systemInfo.timeStart = app.devinfo.timeStart;
systemInfo.timeStop = app.devinfo.timeStop;

save([pathnm filenm],'-mat','SD','ml','d','s','t','dStd','aux','tdml','systemInfo')
