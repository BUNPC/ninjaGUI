function [SP,Commands,Functions] = setEnvCW6(app)
%SETENVCW6 Summary of this function goes here
%   Detailed explanation goes here
                    %serial port parameters for CW6
                    SP.byteorder='bigendian';
                    SP.DataBits=8;
                    SP.StopBits=1;
                    SP.Parity='odd';
                    SP.FlowControl='none';
                    
                    %set serial commands
                    Commands.LaserOff='LASR 0000\r\n';
                    Commands.Stop='STOP \r\n';
                    Commands.PIDN='PIDN 1 \r\n';
                    
                                         
                    %set anonnymous functions
                    Functions.loadCFG=@() cw6_loadCFG();   %function to load the cfg file for the cw6
%                     Functions.dev_init=@(x)cw6_init(app);   %function to initialize UI based on device
%                     Functions.dev_auxListUpdate=@(x)cw6_auxListUpdate(app);    %function to set the names of the aux channels
%                     Functions.dev_InitRecords=@(x)cw6_InitRecords(x);
%                     Functions.dev_cfgFile_updateCom=@(x)cw6_cfgFile_updateCom(x);  %function to update comport in cfg file
%                     Functions.dev_readBytesAvailable=@(x,y,z)cw6_readBytesAvailable(x,y,z);  %function that triggers upon receiving serial bytes
%                     Functions.dev_DisplayData=@(x)cw6_DisplayData(x);  %function to plot data, typically after readBytesAvailable
%                     Functions.dev_SaveData=@(x,y)cw6_SaveData(x,y);  %function to save NIRS data to file
%                     Functions.dev_plotAxesSDG=@(x)cw6_plotAxesSDG(x);
%                     Functions.dev_sdgToggleLines=@(x,y,z)cw6_sdgToggleLines(x,y,z);
%                     Functions.dev_firmwareVer=@(x)cw6_firmwareVer(x);   %read firmware
%                     Functions.dev_SetupSimulation=@(x)cw6_SetupSimulation(x);  %setup cw6 simulation
%                     Functions.dev_timerSimulateData=@(x,y,z)cw6_timerSimulateData(x,y,z); %simulate cw6 data
%                     Functions.dev_toggleLasers=@(x,y)cw6_toggleLasers( x,y);   
                    
%                     %junk dna
%                     %is this always true for CW6? if not, find a way to customize it
%                     app.devinfo.nDets=32;
%                     app.devinfo.nSrcs=32;
%                     
%                     % decide how to customize this
%                     app.devinfo.version = {'1.6','0'};
%                     app.devinfo.firmware = '';
end

