% Matlab helper functions for NN22_ControlBoard00
% 
% Initial version: 2022-12-30
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center

function uploadToStatReg(s, D, skipreadback)

% Example
% Dt = randi(2,1,32)-1; Dt(:,25:end) = 0;
% uploadToStatReg(s, Dt, false);

if nargin < 3
    skipreadback = true;
end

offset = 64;

valbytes = zeros(1,4);
cmdbytes = zeros(1,2);

% write D to Status register
for iv = 1:4
    valbytes(iv) = sum(D(1,(4-iv)*8 + (1:8)) .* 2.^(0:7));
end
cmdbytes(1) = 128 + offset;
cmdbytes(2) = 1;
write(s, [zeros(1,8), 255, cmdbytes, valbytes], 'uint8'); % zeros to flush FSM

% read back from stat reg
if ~skipreadback
    s.flush();
    cmdbytes(1) = offset;
    cmdbytes(2) = 1;
    write(s, [255, cmdbytes, zeros(1,4)], 'uint8'); % read command
    rb = read(s, 6, 'uint8');

    if ~all(cmdbytes == rb(1:2))
        disp("Command readback error");
    end
    if ~all(valbytes == rb(3:6))
        disp("Stat Reg data readback error");
    end
end








