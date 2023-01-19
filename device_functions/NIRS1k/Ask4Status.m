function status=Ask4Status(app)
% Queries the status of the device, if compatible. Can be used to determine
% if the hardware is working properly.

CMDSTRING = [254 0 0 0 0 255-255 255-255 0 0 1];
write(app.sp,CMDSTRING,"uint8");
status=1;