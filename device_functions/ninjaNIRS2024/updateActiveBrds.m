% Matlab helper functions for NN22_ControlBoard00
% 
% Initial version: 2023-3-21
% Revision for VCCS: 2024-8-8
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center
%
% This function will detect which adapter cards are plugged in 
% and are active by sequentially trying to read from them.
% It will also try to detect whether the IMU MCU is active.

function stat = updateActiveBrds(stat)

N_DET_PER_BOARD = 8;
N_BYTES_PER_DET = 3;
N_BYTES_TO_READ_PER_DETB = N_DET_PER_BOARD*N_BYTES_PER_DET + 4;
N_BYTES_TO_READ_PER_ACCELEROMETER = 3+7*2+1;
N_BYTES_TO_READ_PER_SRCB_RAM_LOC = 7;

if ~stat.v5p1b01_en || ~stat.v5p1b23_en
    disp("Warning: Detectors not powered, cannot determine active detectors accurately");
end

N_DET_SLOTS = 24;
N_SRC_SLOTS = 7;
BRD_RELAY_OFFSET = 48;

stat.detb_active = zeros(1,N_DET_SLOTS);
stat.srcb_active = zeros(1,N_SRC_SLOTS);
stat.acc_active = false;

% bring instrument into a known state
stat.rst_pca = false;
stat.rst_detb(:) = false;
stat.rst_srcb = false;
stat.rst_pico = false;
clk_div_old = stat.clk_div;
stat.clk_div = 20;
stat.run = false;
stat = updateStatReg(stat, true);
stat.s.flush();
pause(0.2);
stat.s.flush();
stat = updateStatReg(stat, false);
tmp_rama = zeros(1024,32);
tmp_rama(:,9) = 1; % set stop bit
uploadToRAM(stat, tmp_rama, 'a', false); 

% turn off Matlab warning for no serial data
warning('off','serialport:serialport:ReadWarning');

old_timeout = stat.s.Timeout;


%% Check for active/plugged in detector boards
for idatasrc = 1:N_DET_SLOTS
    stat.s.flush();
    uploadToRAM(stat, genSingleSourceRAMB(idatasrc), 'b', false);
    stat.run = true;
    stat = updateStatReg(stat, true);
    stat.s.Timeout = 0.1;
    buf = read(stat.s, N_BYTES_TO_READ_PER_DETB, 'uint8');
    stat.s.Timeout = old_timeout;
    stat.run = false;
    stat = updateStatReg(stat, true);
        
    if length(buf)==N_BYTES_TO_READ_PER_DETB
        if buf(1)==253 && buf(2)==252 %check packet header
            stat.detb_active(idatasrc) = true;
        end
    end

    pause(0.1);
    stat.s.flush();
    pause(0.01);
end
stat.n_detb_active = sum(stat.detb_active);

%% Check whether IMU / accelerometer is connected to control board
stat.s.flush();
uploadToRAM(stat, genSingleSourceRAMB(idatasrc+1), 'b', false);
stat.run = true;
stat = updateStatReg(stat);
stat.s.Timeout = 0.1;
buf = read(stat.s, N_BYTES_TO_READ_PER_ACCELEROMETER, 'uint8');
stat.s.Timeout = old_timeout;
stat.run = false;
stat = updateStatReg(stat);

if length(buf)==N_BYTES_TO_READ_PER_ACCELEROMETER
    if buf(1)==249 && buf(2)==248 %check packet header
        % check that acc is actually connected
        % buf(4:5) would be the temperature reading, which is unlikely = 0
        if buf(4)~=0 || buf(5)~=0
            stat.acc_active = true;
        end
    else
        disp("Received bad acc packet error.")
    end
end

%% Check for active/plugged in source boards
for idatasrc = 1:N_SRC_SLOTS
    stat.s.flush();
    % set mux to source board
    uploadToRAM(stat, genSingleSourceRAMB(idatasrc +32, true), 'b', false);
    % try to read data from ram location 0
    cmdbuf = zeros(1,(1+2+4));
    cmdbuf(1) = 255;
    cmdbuf(3) = BRD_RELAY_OFFSET; % read command
    write(stat.s, cmdbuf, "uint8");

    stat.s.Timeout = 0.1;
    buf = read(stat.s, N_BYTES_TO_READ_PER_SRCB_RAM_LOC, 'uint8');
    stat.s.Timeout = old_timeout;

    if length(buf)==N_BYTES_TO_READ_PER_SRCB_RAM_LOC
        if buf(1)==255 && buf(2)==0 && buf(3)==48 %check packet header
            stat.srcb_active(idatasrc) = true;
        end
    end

    stat.s.flush();
    pause(0.01);
end
stat.n_srcb_active = sum(stat.srcb_active);

warning('on');
stat.s.flush();
pause(0.2);
stat.s.flush();
stat.clk_div = clk_div_old;
stat = updateStatReg(stat, false);

