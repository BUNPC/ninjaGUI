function [env,error] = setEnv(devinfo)
%SETENV Sets the serial ports parameters, serial commands and device
%functions associated with a compatible NIRS hardware
%   Devinfo is a structure containing hardware information about the nirs
%   device, including its type
env=[];
error=0;

HW=devinfo.devID;


%Starting from 12/20/2020, the following serial port parameters HAVE to be
%specified: BaudRate, Parity, DataBits, StopBits, FlowControl, ByteOrder,
%TimeOut. Buffersize is not compatible anymore

%set the serial port parameters
switch HW
    case 'CW6'
        SP.BaudRate=9600;
        SP.Parity='odd';
        SP.DataBits=8;
        SP.StopBits=1;
        SP.FlowControl='none';        
        SP.ByteOrder='big-endian';
        SP.TimeOut=1.6;                
    case 'ninjaNIRS'
        SP.BaudRate=4e6;
        SP.Parity='none';
        SP.DataBits=8;
        SP.StopBits=1;
        SP.FlowControl= 'hardware';
        SP.ByteOrder='little-endian';
        SP.TimeOut=1.6;                
    case 'fNIRS1k'
        SP.BaudRate=12000000;
        SP.Parity='none';
        SP.DataBits=8;
        SP.StopBits=1;
        SP.FlowControl='hardware';        
        SP.ByteOrder='little-endian';
        SP.TimeOut=1.6;
    otherwise
        disp('Device not compatible with this version')
        error=1;
        return
end
env.SPparams=SP;

%set the functions
switch HW
    case 'CW6'
        func=[];
    case 'ninjaNIRS'
        addpath(genpath(['device_functions',filesep,'ninjaNIRS1']))
        func.ReadBytesAvailable=@(app)ninja_ReadBytesAvailable(app.sp,app.devinfo,app.nSD,app.rbytes,app.fstreamID); %reads the data from the serial port and returns only the data specified by the measurement list
        %func.FlushBuffer=@(app)ninja_FlushBuffer(app.sp);
        func.MapFrequencies=@(app,statemap)ninja_MapFrequencies(app.sp,statemap);
        func.Ask4Status=@(app)ninja_Ask4Status(app);
    case 'fNIRS1k'
        addpath(genpath(['device_functions',filesep,'fNIRS1kv1']))
        func.ReadBytesAvailable=@(app)fNIRS1k_ReadBytesAvailable(app.sp,app.devinfo,app.nSD,app.rbytes,app.fstreamID); %reads the data from the serial port and returns only the data specified by the measurement list
        %func.FlushBuffer=@(app)fNIRS1k_FlushBuffer(app.sp);
        func.MapFrequencies=@(app,statemap)fNIRS1k_MapFrequencies(app.sp,statemap);        
        func.Ask4Status=@(app)fNIRS1k_Ask4Status(app);
        func.convBytes2nirs=@(app)fNIRS1k_convBytes2nirs(app.fstreamID,app.devinfo,app.nSD);        
end
env.functions=func;

%set the serial commands
switch HW
    case 'CW6'
        comms.LightsOff=@(app)'LASR 0000\r\n';  %command to turn all lights off
        comms.Start=@(app)'RUN \r\n';
        comms.Stop=@(app)'STOP \r\n';
    case 'ninjaNIRS'
        CMD_LED_STATE = bin2dec('11000010');
        CMD_ACQ_ON = bin2dec('11000101');
        CMD_ACQ_OFF = bin2dec('11000110');
        comms.LightsOff=@(app)[2 255 CMD_LED_STATE 0]; %command to turn all lights off
        comms.LightsOn=@(app)[2 255 CMD_LED_STATE 12]; %command to turn all lights on
        comms.SourceNOn=@(app,N,L)[2 N-1 CMD_LED_STATE round(15/2*(sign(L)).^2+9/2*(sign(L)))];  %Turns on source N at level L: L=0 off, L=1 high, L=-1 low
        comms.SourceNOff=@(app,N)[2 N-1 CMD_LED_STATE 0];  %Turns off source N
        comms.SourceNIndL=@(app,N,L)[2 N-1 CMD_LED_STATE round(5*(sign(L(1))).^2+3*(sign(L(1))))+round(5/2*(sign(L(2))).^2+3/2*(sign(L(2))))];  %Changes state of each LED on source N individually; L should be a 1x2 vector specifying each level
        comms.Start=@(app)[1 255 CMD_ACQ_ON];
        comms.Stop=@(app)[1 255 CMD_ACQ_OFF];
    case 'fNIRS1k'
        comms.LightsOff=@(app)[254 0 0 0 0 255-255 255-255 0 0 app.active]; %command to turn all lights off
        comms.LightsOn=@(app)[254 0 0 0 0 255-255 255-255 15 15 app.active]; %command to turn all lights on
        %the three following commands are identical due to the way the
        %command words are written for this device; we cannot control each
        %individually nor without sending a command to the ACQ. Also, we
        %cannot control intensity levels for this device
        comms.SourceNOn=@(app,N,L)[254 0 0 0 0 255-255 255-255 bin2dec(num2str(flipud(app.LEDstate)'))' app.active];  %Turns on source N at level L: L=0 off, L=1 high, L=-1 low
        comms.SourceNOff=@(app,N)[254 0 0 0 0 255-255 255-255 bin2dec(num2str(flipud(app.LEDstate)'))' app.active];  %Turns off source N
        comms.SourceNIndL=@(app,N,L)[254 0 0 0 0 255-255 255-255 bin2dec(num2str(flipud(app.LEDstate)'))' app.active];  %Only one level allowed, so L is not used in this
        comms.Start=@(app)[254 0 0 0 0 255-255 255-255 bin2dec(num2str(flipud(app.LEDstate)'))' 1]; %command to start acquisition
        comms.Stop=@(app)[254 0 0 0 0 255-255 255-255 bin2dec(num2str(flipud(app.LEDstate)'))' 0]; %command to stop acquisition                
end
env.commands=comms;


end

