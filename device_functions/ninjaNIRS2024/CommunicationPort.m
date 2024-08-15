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
%         try

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
            stat = struct();
            stat.s = s;
            stat = initStat(stat);

            disp('Serial communication established!')
            uploadToRAM( stat, stat.rama, 'a', false);
            uploadToRAM( stat, stat.ramb, 'b', false);
            stat = powerOn( stat);
            stat = ResetCounters(s,stat);
            app.deviceInformation.stat=stat;
            app.deviceInformation.nDetBoards = stat.n_detb_active;
            errors=0;            
%         catch ME
%             disp(ME.message)           
%             errors=1;            
%         end
        port=app.sp;
    case 'close'
        delete(app.sp);%close serial communication
        port=[];
    case 'flush'
        app.deviceInformation.stat=ResetCounters(app.sp,app.deviceInformation.stat);        
        port=app.sp;
end