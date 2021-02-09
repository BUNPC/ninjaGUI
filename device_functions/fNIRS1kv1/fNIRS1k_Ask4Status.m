function status=fNIRS1k_Ask4Status(app)
% Queries the status of the device. Right now it doesn't actually query
% anything, it's just used as an excuse to to initialize the detectors

% disp('Querying fNIRS1000 status...')

CMDSTRING = [254 0 0 0 0 255-255 255-255 0 0 1];
write(app.sp,CMDSTRING,"uint8");
status=1;

