function errors = Acquisition(app,action)
%ACQUISITION Starts or stops acquisitions
%   action is either 'start' or 'stop'
errors=0;

try
    switch action
        case 'start'
%             %first make sure the acquisition is stopped
%             app.deviceInformation.stat.run = false;
%             app.deviceInformation.stat= updateStatReg(app.deviceInformation.stat);
%commented code above didn't work, for some reason it does not run
            %now start it
            app.deviceInformation.stat=StartAcquisition(app.sp,app.deviceInformation.stat);
        case 'stop'
            %% stop acquisition
            app.deviceInformation.stat.run = false;
            app.deviceInformation.stat = updateStatReg(app.sp,app.deviceInformation.stat);
    end
catch
    errors=1;
end
end

