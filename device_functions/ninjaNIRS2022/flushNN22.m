% Matlab helper functions for NN22_ControlBoard00
% 
% Initial version: 2023-3-4
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center
%
% This function will flush serial data from all microcontrollers and the
% FPGA

function stat = flushNN22(sp,stat)


% make sure system is not running
stat.run = false;
stat = updateStatReg(sp,stat);
pause(0.1);

% Reset program counters 
sp.flush();
stat.rst_pca = true;
stat.rst_detb = ones(1,4);
stat.rst_ram = true; % reset external ram
stat = updateStatReg(sp,stat);

pause(0.1);
stat.rst_pca = false;
stat.rst_ram = false;
for ii = 1:4
    stat.rst_detb(ii) = 0;
    stat = updateStatReg(sp,stat);
    pause(0.5);
end
pause(0.5);

% Redundant: also run a bit without sampling
% (flush data out of tx buffers in all microcontrollers)
ramb_tmp = stat.ramb;
ramb_tmp(:,[9 10]) = 0; % reprog RAM B
uploadToRAM(sp, ramb_tmp, 'b', false);
stat.run = true;
stat = updateStatReg(sp,stat);
pause(0.1);
stat.run = false;
stat = updateStatReg(sp,stat);
pause(0.1);
sp.flush();
pause(0.2);
sp.flush();

% Restore RAM B
uploadToRAM(sp, stat.ramb, 'b', false);
