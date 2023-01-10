% Matlab helper functions for NN22_ControlBoard00
% 
% Initial version: 2023-1-4
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center

function [A, stat] = collectDataNN22_01(stat)

N_DETBOARDS = 1;
N_DET_PER_BOARD = 8;
N_BYTES_PER_DET = 3;

N_STATES = 2;

N_BYTES_TO_READ_PER_DETB = N_DET_PER_BOARD*N_BYTES_PER_DET + 4;
N_BYTES_TO_READ_PER_HEADER = 3;

N_SAMPLES_TO_READ = 1*10*60;

OFFSET_ARRAY = 0:N_BYTES_TO_READ_PER_DETB:((N_DETBOARDS-1)*N_BYTES_TO_READ_PER_DETB);
OFFSET_ARRAY_RES = OFFSET_ARRAY + (0:N_BYTES_PER_DET:((N_DET_PER_BOARD-1)*N_BYTES_PER_DET))';
OFFSET_ARRAY_RES = OFFSET_ARRAY_RES(:)';


detsmpcnt = 0;
statecnt = 0;
smpcnt = 1;

A = zeros(N_SAMPLES_TO_READ, N_STATES, N_DETBOARDS*N_DET_PER_BOARD);

% Reset program counters 
stat.s.flush();
stat.rst_pca = true;
stat.rst_pcb = true;
stat.rst_clkdiv = true;
stat.rst_detb = true;
stat = updateStatReg(stat);

% Run
stat.rst_pca = false;
stat.rst_pcb = false;
stat.rst_clkdiv = false;
stat.rst_detb = false;
stat = updateStatReg(stat);
pause(0.6);
stat.run = true;
stat = updateStatReg(stat);

% discard first result (not valid)
read(stat.s, N_BYTES_TO_READ_PER_HEADER + N_BYTES_TO_READ_PER_DETB*N_DETBOARDS, 'uint8');

while smpcnt <= N_SAMPLES_TO_READ
    
    % read and check sample header sent by FPGA
    raw = read(stat.s, N_BYTES_TO_READ_PER_HEADER, 'uint8');
    if raw(1) ~= 254
        disp('Sample header error');
    end
    statecnt_rd = (raw(2)*256+raw(3));
    if statecnt_rd ~= mod(statecnt+1, N_STATES)
        disp(['State count error. rd=' num2str(statecnt_rd) ' ex=' num2str(mod(statecnt+1, N_STATES))]);
    end
    statecnt = statecnt_rd;

    % read, check and store data sent by detector boards
    raw = read(stat.s, N_BYTES_TO_READ_PER_DETB*N_DETBOARDS, 'uint8');
    if any(raw(1+OFFSET_ARRAY) ~= 253)
        disp('Det board header 1 error');
    end
    if any(raw(2+OFFSET_ARRAY) ~= 252)
        disp('Det board header 2 error');
    end
    if any(raw(3+OFFSET_ARRAY) ~= mod(detsmpcnt+1, 256))
        disp('Det board sample counter error');
    end
    detsmpcnt = raw(3);
    val = zeros(1,N_DETBOARDS*N_DET_PER_BOARD);
    for ii = 1:N_BYTES_PER_DET
        val = val + 256^(ii-1)*raw(3 + ii + OFFSET_ARRAY_RES);
    end
    % two's complement conversion & inversion so that we normally have 
    % positive numbers
    val = (val > 2^23-1).*2^24 - val;

    A(smpcnt,1+mod(statecnt-1,N_STATES),:) = val;
    
    if statecnt == 0
        smpcnt = smpcnt +1;
    end
end

stat.run = false;
stat = updateStatReg(stat);



