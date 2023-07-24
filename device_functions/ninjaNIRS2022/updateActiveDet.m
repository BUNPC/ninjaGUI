% Matlab helper functions for NN22_ControlBoard00
% 
% Initial version: 2023-3-21
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center
%
% This function will detect which detector adapter cards are plugged in 
% and are active by sequentially trying to read from them.
% It will also try to detect whether the IMU MCU is active.

function stat = updateActiveDet(sp,stat)

N_DET_PER_BOARD = 8;
N_BYTES_PER_DET = 3;
N_BYTES_TO_READ_PER_DETB = N_DET_PER_BOARD*N_BYTES_PER_DET + 4;
N_BYTES_TO_READ_PER_ACCELEROMETER = 3+7*2+1;

if ~stat.v5p1b01_en || ~stat.v5p1b23_en
    disp("Warning: Detectors not powered, cannot determine active detectors accurately");
end

N_DET_SLOTS = 24;

stat.detb_active = zeros(1,N_DET_SLOTS);
stat.acc_active = false;

% bring instrument into a known state
stat.rst_pca = false;
stat.rst_detb(:) = false;
clk_div_old = stat.clk_div;
stat.clk_div = 250;
stat.run = false;
stat = updateStatReg(sp,stat, true);
sp.flush();
pause(0.2);
sp.flush();
stat = updateStatReg(sp,stat, false);

% turn off Matlab warning for no serial data
warning('off','serialport:serialport:ReadWarning');

old_timeout = sp.Timeout;

for isrc = 1:N_DET_SLOTS
    sp.flush();
    uploadToRAM(sp, genSingleSourceRAMB(isrc), 'b', false);
    stat.run = true;
    stat = updateStatReg(sp,stat, true);
    sp.Timeout = 0.1;
    buf = read(sp, N_BYTES_TO_READ_PER_DETB, 'uint8');
    sp.Timeout = old_timeout;
    stat.run = false;
    stat = updateStatReg(sp,stat, true);
        
    if length(buf)==N_BYTES_TO_READ_PER_DETB
        if buf(1)==253 && buf(2)==252 %check packet header
            stat.detb_active(isrc) = true;
        end
    end

    sp.flush();
    pause(0.01);
end
stat.n_detb_active = sum(stat.detb_active);

sp.flush();
uploadToRAM(sp, genSingleSourceRAMB(isrc+1), 'b', false);
stat.run = true;
stat = updateStatReg(sp,stat);
sp.Timeout = 0.1;
buf = read(sp, N_BYTES_TO_READ_PER_ACCELEROMETER, 'uint8');
sp.Timeout = old_timeout;
stat.run = false;
stat = updateStatReg(sp,stat);

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

warning('on');
sp.flush();
pause(0.2);
sp.flush();
stat.clk_div = clk_div_old;
stat = updateStatReg(sp,stat, false);



function ramb = genSingleSourceRAMB(isrc)
% Generate RAM B contents to collect data only from a single data souce.
%
% Initial version: 2023-3-21
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center

ramb = zeros(1024,32);

% set source selector bits (UART Rx Mux)
ramb(:, 1:5) = repmat(bitget(isrc-1, 1:5 ,'uint8'),1024,1);
% set flow enable bit (DetB Rx En)
ramb(:, 6) = 1;

% write end cycle bits
ramb(10:500,9) = 1;

