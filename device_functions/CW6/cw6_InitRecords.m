function cw6_InitRecords(app)

ml = app.devinfo.SD.MeasList;

wpr = size(ml,1) + app.devinfo.nAux + 2; % # meas + 4 aux channels + 2 header words

recordRate = app.devinfo.recordRate;
recordsPerDisplay = app.devinfo.recordRate;
bytesPerDisplay = wpr*4*recordsPerDisplay;

app.devinfo.recordRate = recordRate;
app.devinfo.bytesPerDisplay = bytesPerDisplay;
app.devinfo.wordsPerDisplay = bytesPerDisplay/4;
app.devinfo.recordsPerDisplay = recordsPerDisplay;
app.devinfo.WordsPerRecord = wpr;
app.devinfo.SPbuffersize = 1024*1024*2;   % serial port buffer size 1 meg byte
app.devinfo.data = zeros(wpr,recordRate*60); % words per record by 25 records/s,60 s/min, 60 min

app.devinfo.nRecords = 1;