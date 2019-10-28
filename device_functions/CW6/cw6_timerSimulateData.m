function cw6_timerSimulateData(obj,event,app)




tstep = 1/25;

tPerTask = 1;

tt = get(obj,'TasksExecuted')*tPerTask;

t = [(tt-tPerTask+tstep):tstep:tt];

% dGain = app.devinfo.gain(app.devinfo.plot(:,2))';
% dCC = app.cw6simul.detCC(app.devinfo.plot(:,2))';
% sCC = app.cw6simul.srcCC(app.devinfo.plot(:,1))';
% 
% d = dGain.*dCC.*sCC*(1*sin(2*pi*1*t) + 5*cos(2*pi*0.1*t));
% 
% axes(app.displayAxes)
% plot(t,d)


%dGain = app.devinfo.gain( app.devinfo.SD.MeasList(:,2) )';
dCC = app.cw6simul.detCC( app.devinfo.SD.MeasList(:,2) )';
sCC = app.cw6simul.srcCC( app.devinfo.SD.MeasList(:,1) )';

nml = size( app.devinfo.SD.MeasList(:,1), 1);
nt = length(t);

lst1 = find(app.devinfo.SD.MeasList(:,4)==1);
lst2 = find(app.devinfo.SD.MeasList(:,4)==2);
nml1 = length(lst1);
nml2 = length(lst2);
d = zeros(nml,nt);
%d = dGain.*dCC.*sCC*(1+0.01*sin(2*pi*1*t) + 0.05*cos(2*pi*0.1*t));% + 0.1*randn(nml,nt);
d(lst1,:) = (100 + dCC(lst1)'*ones(1,nt) + sCC(lst1)*ones(1,nt) + 0.01*ones(nml1,1)*sin(2*pi*1*t)/0.115 + 0.05*ones(nml1,1)*cos(2*pi*0.1*t)/0.115 + 0.003*randn(nml1,nt)/0.115);
d(lst2,:) = (100 + dCC(lst2)'*ones(1,nt) + sCC(lst2)*ones(1,nt) - 0.01*ones(nml2,1)*sin(2*pi*1*t)/0.115 - 0.05*ones(nml2,1)*cos(2*pi*0.1*t)/0.115 + 0.003*randn(nml2,nt)/0.115);

app.devinfo.time(app.devinfo.tPtr+[1:length(t)]) = t/app.devinfo.recordRate;
app.devinfo.time(app.devinfo.tPtr+[1:length(t)]) = t;
app.devinfo.tPtr = app.devinfo.tPtr + length(t);

app.devinfo.data(1:nml, app.devinfo.dataPtr+[1:size(d,2)]) = d;
app.devinfo.dataPtr = app.devinfo.dataPtr + size(d,2);

% Check SNR and update SDG plot if exceed noise threshold
app.devinfo.dataStd = std(d,[],2) ./ mean(d,2);
%if max(app.devinfo.dataStd) > app.devinfo.stdThresh
    cw6_plotAxesSDG(app)
%end

%app.devinfo.nRecords = app.devinfo.dataPtr / app.devinfo.WordsPerRecord;
app.devinfo.nRecords = tt/tstep;



cw6_DisplayData(app)

% this will update SDG signal level warnings
if app.devinfo.SDGdisplayLevel
    cw6_plotAxesSDG(app)
end




