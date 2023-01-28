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
            disp('Simulator mode initiated!')
            errors=0;
        catch ME
            disp(ME.message)           
            errors=1;            
        end
        app.sp.Port='Simulator';
        port=[];
    case 'close'
        delete(app.sp);%close serial communication
        port=[];
    case 'flush'
        
end