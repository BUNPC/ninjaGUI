% Matlab helper functions for NN22_ControlBoard00
% 
% Initial version: 2023-1-2
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center

function stat = powerOn(sp,stat)

% turn power on to subsystems sequentially
% repeated update calls will create natural delay
stat.vn22clk_en = true;
stat.v5p1rpi_en = true;
stat = updateStatReg(sp,stat);
stat.v5p1b23_en = true;
stat = updateStatReg(sp,stat);
stat.v5p1b01_en = true;
stat = updateStatReg(sp,stat);
stat.vn3p4_en = true;
stat = updateStatReg(sp,stat);
stat.v9p0_en = true;
stat = updateStatReg(sp,stat);
stat.vn22_en = true;
stat = updateStatReg(sp,stat);
stat.v5p1src_en = true;
stat = updateStatReg(sp,stat);

% this section does not need a delay
stat.rst_pca = false;
stat.rst_pcb = false;
stat.rst_clkdiv = false;
stat.rst_detb = false;
stat.run = false;
stat = updateStatReg(sp,stat);

