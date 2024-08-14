% Matlab helper functions for NN22_ControlBoard00
% 
% Initial version: 2023-1-2
% Revision for VCCS: 2024-7-18
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center

function stat = powerOn(stat)

% turn power on to subsystems sequentially
% repeated update calls will create natural delay
stat.vn22clk_en = true;
stat.v5p1rpi_off = false;
stat.rst_pico = false;
stat = updateStatReg(stat);
stat.v5p1b23_en = true;
stat = updateStatReg(stat);
stat.v5p1b01_en = true;
stat = updateStatReg(stat);
stat.vn3p4_en = true;
stat = updateStatReg(stat);
stat.v9p0_en = true;
stat = updateStatReg(stat);
stat.vn22_en = true;
stat = updateStatReg(stat);
stat.v5p1src_en = true;
stat = updateStatReg(stat);

% releasing the reset on the detector cards
% detector cards will in turn power on the detector optodes
% turning on the power one backplane at a time to reduce the spike in
% current draw
for ii = 1:4
    stat.rst_detb(ii) = 0;
    stat = updateStatReg(stat);
    pause(0.5);
end

stat.rst_srcb = false;
stat = updateStatReg(stat);
pause(0.2);

% this section does not need a delay
stat.rst_pca = false;
stat.run = false;
stat = updateStatReg(stat);

