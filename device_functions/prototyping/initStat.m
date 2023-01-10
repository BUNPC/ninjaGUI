% Matlab helper functions for NN22_ControlBoard00
% 
% Initial version: 2023-1-2
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center

function stat = initStat()
%%
stat.vn22clk_en = false;
stat.vn3p4_en = false;
stat.vn22_en = false;
stat.v9p0_en = false;
stat.v5p1src_en = false;
stat.v5p1rpi_en = false;
stat.v5p1b23_en = false;
stat.v5p1b01_en = false;

% main clock divider
% determines period of 'B' state
% t_bstate = clk_div*8/96e6
stat.clk_div = 12;

% reset program counter a
stat.rst_pca = true;
% reset program counter b
stat.rst_pcb = true;
% reset clk_div
stat.rst_clkdiv = true;
% reset rp2040 on all detector boards (held in reset while true)
stat.rst_detb = true;

% clk_div will not advance if false -> also a and b not advancing
stat.run = false;

stat.sreg = zeros(1,32);

%% RAM A

stat.rama = zeros(1024,32);

% Example switching through all power states and wavelength of source 1
% with a dark state after each on state

% stat.rama(1,[1 9]) = 1; % select LED
% stat.rama(1,19:21) = [1 0 0]; % power level high
% % dark state inbetween
% stat.rama(3,[1 9]) = 1; % select LED
% stat.rama(3,19:21) = [0 1 0]; % power level mid
% % dark state inbetween
% stat.rama(5,[1 9]) = 1; % select LED
% stat.rama(5,19:21) = [0 0 1]; % power level low
% % dark state inbetween
% stat.rama(7,[1 10]) = 1; % select LED
% stat.rama(7,19:21) = [1 0 0]; % power level high
% % dark state inbetween
% stat.rama(9,[1 10]) = 1; % select LED
% stat.rama(9,19:21) = [0 1 0]; % power level mid
% % dark state inbetween
% stat.rama(11,[1 10]) = 1; % select LED
% stat.rama(11,19:21) = [0 0 1]; % power level low
% dark state inbetween
% stat.rama(12:end,27) = 1; % mark sequence end

% Example using only one wavelength and power setting of source 1
% Used e.g. for filter wheel tests
stat.rama(1,[1 9]) = 1; % select LED
stat.rama(1,19:21) = [0 1 0]; % power level med
stat.rama(2:end,27) = 1; % mark sequence end



%% RAM B

stat.ramb = zeros(1024,32);

n_state_b = 1000; % number of used RAM B states
n_detb = 16; % number of detector boards
% to-do: replace n_detb with array of active detectors
% to-do: write init/helper function that detects which/how many boards are
% plugged in
t_end_cyc = 10e-6; % duration of end cycle pulse period
t_bsel_holdoff = 1e-6; % holdoff between different selected detector board uart transmissions
t_smp_holdoff_start = 150e-6; % time to hold off sampling after state switch to let analog signal settle
t_smp_holdoff_end = 10e-6; % time to hold off sampling before state switch (at end of cycle)
fs_target = 2e3; % target sampling frequency

t_state_b = stat.clk_div*8/96e6; % duration of each RAM B state
t_state_a = t_state_b * n_state_b;

ni_smp = round(1/fs_target/t_state_b); % number
ni_smp_on = floor(ni_smp/2);

% write end cycle bits
stat.ramb(1+(1:round(t_end_cyc/t_state_b)),9) = 1; 

% write adc sampling bits
for ii = 1:ni_smp_on
    si = round(t_smp_holdoff_start/t_state_b) + ii -1;
    se = n_state_b - round(t_smp_holdoff_end/t_state_b)  + ii -1;
    % to-do: check that se + ni_smp_off < n_state_b
    stat.ramb(si:ni_smp:se, 10) = 1;
end

% data transmission management
ni_bsel = floor((n_state_b - round(t_end_cyc/t_state_b)-1 - (n_detb+1)*ceil(t_bsel_holdoff/t_state_b))/n_detb);
% to-do: verify that ni_bsel*t_state_b is long enough to transfer data from
% one cylce and one board
si = round(t_end_cyc/t_state_b)+1 + ceil(t_bsel_holdoff/t_state_b);
stat.ramb(si-1,8) = 1; % transmit program counter A
for ii = 1:n_detb
    stat.ramb(si:(si+ni_bsel-1), 1:4) = repmat(bitget(ii-1, 1:4 ,'uint8'),ni_bsel,1);
    stat.ramb((si+2):(si+ni_bsel-1), 6) = 1;
    si = si + ni_bsel + ceil(t_bsel_holdoff/t_state_b);
end

stat.ramb(n_state_b:end,18) = 1; % mark sequence end

%% serial port

stat.s = serialport("COM7", 6000000, 'FlowControl', 'hardware');
























