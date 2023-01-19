function errors = Acquisition(app,action)
%ACQUISITION Starts or stops acquisitions
%   action is either 'start' or 'stop'
errors=0;

startCommand=[254 0 0 0 0 0 0 bin2dec(num2str(flipud(app.LEDstate)'))' 1]; %command to start acquisition
stopCommand=[254 0 0 0 0 0 0 bin2dec(num2str(flipud(app.LEDstate)'))' 0]; %command to stop acquisition


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

