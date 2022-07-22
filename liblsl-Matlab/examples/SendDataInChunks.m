addpath(genpath('..'))
% instantiate the library
disp('Loading library...');
lib = lsl_loadlib();

% make a new stream outlet
disp('Creating a new streaminfo...');
info = lsl_streaminfo(lib,'ninja','EEG',8,100,'cf_float32','sdfwerr32432');

disp('Opening an outlet...');
outlet = lsl_outlet(info);

% send data into the outlet
disp('Now transmitting chunked data...');
while true
    outlet.push_chunk(randn(8,50));
    pause(5);
end