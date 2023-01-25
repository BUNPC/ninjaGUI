function errors = Acquisition(app,action)
%ACQUISITION Starts or stops acquisitions
%   action is either 'start' or 'stop'
errors=0;

CMD_ACQ_ON = bin2dec('11000101');
CMD_ACQ_OFF = bin2dec('11000110');

startCommand=[1 255 CMD_ACQ_ON];
stopCommand=[1 255 CMD_ACQ_OFF];

try
    switch action
        case 'start'
            write(app.sp,startCommand,"uint8");
        case 'stop'
            write(app.sp,stopCommand,"uint8");
    end
catch
    errors=1;
end
end
