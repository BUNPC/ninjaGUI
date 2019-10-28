
s = instrfind('Port','COM8');
if isempty(s)
    s = serial(acport);
    s.BaudRate = 2000000;
    s.InputBufferSize = 1000000;
    s.OutputBufferSize = 1000000;
    s.FlowControl = 'hardware';
    s.Timeout = 1.6;
    fopen(s);
end
if strcmp(s.status,'closed')
    try
        s = serial(acport);
        s.BaudRate = 2000000;
        s.InputBufferSize = 1000000;
        s.OutputBufferSize = 1000000;
        s.FlowControl = 'hardware';
        s.Timeout = 1.6;
        fopen(s);
    catch
        s=[];
    end
end

CMD_LED_STATE = bin2dec('11000010');
CMD_SEL_F1 = bin2dec('11000011');
CMD_SEL_F2 = bin2dec('11000100');
CMD_ACQ_ON = bin2dec('11000101');
CMD_ACQ_OFF = bin2dec('11000110');

% Flush Buffer
ba = s.BytesAvailable;
while ba > 0
    fread(s,ba,'uchar');
    ba = s.BytesAvailable;
end

LED_CMD=12;

%set LED state
fwrite(s,[2 0 CMD_LED_STATE LED_CMD]);
%set LED frequency
fwrite(s,[4 0 CMD_SEL_F1 1 CMD_SEL_F2 2]);

%start acq
fwrite(s,[1 255 CMD_ACQ_ON]);


dev.nDets=4;

data=nan(4,1000,6);

for k=1:1000
data(:,k,:)=ninja_ReadBytesAvailable(s,dev);
end


%stop acq
fwrite(s,[1 255 CMD_ACQ_OFF]);

%turn LED off
fwrite(s,[2 0 CMD_LED_STATE 0]);