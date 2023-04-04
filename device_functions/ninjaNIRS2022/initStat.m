% Initial version: 2023-1-2
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center
% Modified on 1/11 by Antonio Ortega. Now the ramA map is not a constant.
% It also does not create the serial port since that is going to be done
% elsewhere

function stat = initStat(app,stateMap)
%%
% s=serialport(app.deviceInformation.commPort,app.communicationParameters.BaudRate,...
%                 'Parity',app.communicationParameters.Parity,...
%                 'DataBits',app.communicationParameters.DataBits,...
%                 'StopBits',app.communicationParameters.StopBits,...
%                 'FlowControl',app.communicationParameters.FlowControl,...
%                 'ByteOrder',app.communicationParameters.ByteOrder,...
%                 "Timeout",app.communicationParameters.TimeOut);
% app.sp = s;
stat.s = app.sp;

%%
stat.vn22clk_en = false;
stat.vn3p4_en = false;
stat.vn22_en = false;
stat.v9p0_en = false;
stat.v5p1src_en = false;
stat.v5p1rpi_off = false;
stat.v5p1b23_en = false;
stat.v5p1b01_en = false;

% main clock divider
% determines period of 'B' state
% t_bstate = clk_div*8/96e6
stat.clk_div = 15;

% reset program counter a
stat.rst_pca = true;
% reset rp2040 on all detector boards (held in reset while true)
stat.rst_detb = true;

% clk_div will not advance if false -> also a and b not advancing
stat.run = false;

stat.sreg = zeros(1,32);

stat = powerOn(stat);


%% Determine active detectors and IMU
stat.aux_active = true;
stat = updateActiveDet(stat);

%% RAM A

stat.rama = stateMap; 

%% RAM B

stat.ramb = zeros(1024,32);

% number of used RAM B states
stat.n_state_b = 1000;
% duration of each RAM B state
t_state_b = stat.clk_div*8/96e6; 
% duration of each RAM A state
t_state_a = t_state_b * stat.n_state_b;
% duration of end cycle pulse period
t_end_cyc = 10e-6;
% holdoff between different selected detector board uart transmissions
t_bsel_holdoff = 1e-6;
% minimum duration of each board select period
% (32byted*10bits/6000000baud = 53.4e-6 s)
t_bsel_min = 55e-6;
% time to hold off sampling after state switch to let analog signal settle
% at 350 us the signal should be approx 101% of final value
t_smp_holdoff_start = 350e-6;
% time to hold off sampling before state switch (at end of cycle)
t_smp_holdoff_end = 10e-6; 
% minimum period for each sample 
% (depends on ADC, ADC internal oversampling, transfer to MCU, computation in MCU)
t_smp_min = 2e-6;
% target number of samples to be averaged for each A state
% values >256 risk overflow of the result (ADC: 16bit, result: 24bit)
n_smp_target = 250;
% target ADC sampling perid
t_smp_target = max((t_state_a -t_smp_holdoff_start - t_smp_holdoff_end)/n_smp_target, t_smp_min);

% number of B states for each ADC sample
ni_smp = max(ceil(t_smp_target/t_state_b), 2);
ni_smp_on = floor(ni_smp/2);

% write end cycle bits
stat.ramb(1+(1:ceil(t_end_cyc/t_state_b)),9) = 1; 

% write adc sampling bits
for ii = 1:ni_smp_on
    si = round(t_smp_holdoff_start/t_state_b) + ii -1;
    se = stat.n_state_b - round(t_smp_holdoff_end/t_state_b)  + ii -1;
    % to-do: check that se + ni_smp_off < n_state_b
    stat.ramb(si:ni_smp:se, 10) = 1;
end
% number of samples collected during each A state
% (first sample will be discarded by detector board)
stat.n_smp = length(si:ni_smp:se) -1; 

if stat.n_smp > 255 % 256*16bit number could overflow 24 bit result 
    disp("Warning: nsamples large, overflow possible.")
end

% data transmission management
% number of B states allocated to each UART data source (det boards + IMU)
ni_bsel = floor(( stat.n_state_b - round(t_end_cyc/t_state_b) - 2 - ...
    (stat.n_detb_active+1+stat.acc_active)*ceil(t_bsel_holdoff/t_state_b) ) ...
    / (stat.n_detb_active+stat.acc_active));
if ni_bsel*t_state_b < t_bsel_min
    disp("Warning: t_bsel too short.")
end
si = round(t_end_cyc/t_state_b)+1 + ceil(t_bsel_holdoff/t_state_b);
stat.ramb(si-2,8) = 1; % transmit program counter A
if stat.aux_active
    stat.ramb(si-1,7) = 1; % transmit aux data
end
for ii = find([stat.detb_active, stat.acc_active])
    % set source selector bits (UART Rx Mux)
    stat.ramb(si:(si+ni_bsel-1), 1:5) = repmat(bitget(ii-1, 1:5 ,'uint8'),ni_bsel,1);
    % set flow enable bit (DetB Rx En)
    stat.ramb((si+2):(si+ni_bsel-1), 6) = 1;
    si = si + ni_bsel + ceil(t_bsel_holdoff/t_state_b);
end

stat.ramb(stat.n_state_b:end,18) = 1; % mark sequence end

%% Accelerometer / IMU constants
% these are defined in the IMU MCU firmware
% to-do: read this from the MCU directly (e.g. implement in status packet)
if stat.acc_active
    stat.accfs = 4;
    stat.gyrofs = 250;
end

%% upload RAMs 

uploadToRAM(stat.s, stat.rama, 'a', false);
uploadToRAM(stat.s, stat.ramb, 'b', false);
stat = flushNN22(stat);
























