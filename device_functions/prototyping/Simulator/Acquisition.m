function errors = Acquisition(app,action)
%ACQUISITION Starts or stops acquisitions
%   action is either 'start' or 'stop'
errors=0;

try
    switch action
        case 'start'
            disp('Simulated acquisition started')
        case 'stop'
            disp('Simulated acquisition ended')
    end
catch
    errors=1;
end
end

