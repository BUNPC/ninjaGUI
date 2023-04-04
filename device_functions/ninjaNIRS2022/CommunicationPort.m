function [port,errors] = CommunicationPort(app,command)
%CommunicationPort Used to open or close the serial communication, and also
%to flush the communications buffer
%  commands are 'open', 'close' and 'flush'. 'open' is used to create the
%  port object and open it. 'close' should close the communication and
%  delete the object. 'flush' is used to flush the buffer
% the output 'errors' can be used by the GUI to stop if the communication
% was not established successfully

switch command
    case 'open'
        try
            %dummy state map, a new one will be chosen after the SD file; I
            %am just doing this because I am not sure if the device will
            %break if I power it on or if I connect to it without writing a
            %ram first
            stateMap = zeros(1024,32);
            stateMap(1,[1 9]) = 1; % select LED
            stateMap(1,19:21) = [0 1 0]; % power level mid            
            stateMap(3:end,27) = 1; % mark sequence end
            %Create serial port object
            s=serialport(app.deviceInformation.commPort,app.communicationParameters.BaudRate,...
                'Parity',app.communicationParameters.Parity,...
                'DataBits',app.communicationParameters.DataBits,...
                'StopBits',app.communicationParameters.StopBits,...
                'FlowControl',app.communicationParameters.FlowControl,...
                'ByteOrder',app.communicationParameters.ByteOrder,...
                "Timeout",app.communicationParameters.TimeOut);
            app.sp= s;
%             s.NumBytesAvailable
            stat=initStat(app,stateMap);

            disp('Serial communication established!')
            uploadToRAM(s, stat.rama, 'a', false);
            uploadToRAM(s, stat.ramb, 'b', false);
            stat = powerOn(stat);
            stat = ResetCounters(s,stat);
            app.sp=s;
            app.deviceInformation.stat=stat;
            app.deviceInformation.nDetBoards=ceil(app.deviceInformation.nDets/8); %In case we do not find an automatic way to assign this, it can be based on the number of detectors connected to the system, assuming no empty detector boards
            errors=0;            
        catch ME
            disp(ME.message)           
            errors=1;            
        end
        port=app.sp;
    case 'close'
        delete(app.sp);%close serial communication
        port=[];
    case 'flush'
        app.deviceInformation.stat=ResetCounters(app.sp,app.deviceInformation.stat);        
        port=app.sp;
end