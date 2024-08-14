% Matlab helper functions for NN22_ControlBoard00
% 
% Initial version: 2023-3-4
% Revision for VCCS: 2024-8-11
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center
%
% This function will flush serial data from all microcontrollers and the
% FPGA

function stat = flushNN22(stat, rst_srcb)

if nargin < 2
    rst_srcb = false;
end


% make sure system is not running
stat.run = false;
stat = updateStatReg(stat);
pause(0.1);

% Reset program counters 
stat.s.flush();
stat.rst_pca = true;
stat.rst_detb = ones(1,4);
if rst_srcb
    % resetting srcb will delete srcram in the cards
    stat.rst_srcb = true;
end
stat.rst_ram = true; % reset external ram
stat = updateStatReg(stat);

pause(0.1);
stat.rst_pca = false;
stat.rst_ram = false;
for ii = 1:4
    stat.rst_detb(ii) = 0;
    stat = updateStatReg(stat);
    pause(0.5);
end
stat.rst_srcb = false;
pause(0.5);

% Redundant: also run a bit without sampling
% (flush data out of tx buffers in all microcontrollers)
ramb_tmp = stat.ramb;
ramb_tmp(:,[10 11]) = 0; % reprog RAM B
uploadToRAM(stat, ramb_tmp, 'b', false);
stat.run = true;
stat = updateStatReg(stat);
pause(0.1);
stat.run = false;
stat = updateStatReg(stat);
% wait for max duration for acquisition to finish
pause(stat.nstates*stat.n_state_b*stat.clk_div*8/96e6 + 0.1);
stat.s.flush();
pause(0.2);
stat.s.flush();

% Restore RAM B
uploadToRAM(stat, stat.ramb, 'b', false);
if rst_srcb && isfield(stat, 'srcram') && isfield(stat, 'srcb_active')
    % Restore source rams
    for isrcb = 1:7
        if stat.srcb_active(isrcb)
            uploadToRAM(stat, squeeze(stat.srcram(isrcb,:,:)), 'src', false, isrcb);
        end
    end
end
