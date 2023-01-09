% Matlab helper functions for NN22_ControlBoard00
% 
% Initial version: 2022-12-30
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center

function uploadToRAM(s, D, rselect, skipreadback)

% Dimensions of D should be 1024x32
% RAM sizes are:
% a: 1024x27
% b: 1024x18
% non-zero values outside of these dimension will lead to errors
% non-binary values will lead to errors

% Example
% Dt = randi(2,1024,32)-1; Dt(:,28:end) = 0;
% uploadToRAM(s, Dt, 'a');

% TO-DO: check that elements are 0 or 1
% allow upload of partial RAM blocks

if nargin < 4
    skipreadback = false;
end

if rselect == 'a'
    offset = 16;
elseif rselect == 'b'
    offset = 32;
else
    error('rselect invalid');
end

% flush FSM
write(s, zeros(1,8), 'uint8');

valbytes = zeros(1,4);
cmdbytes = zeros(1,2);

% write D to RAM
for ii = 1:1024
    for iv = 1:4
        valbytes(iv) = sum(D(ii,(4-iv)*8 + (1:8)) .* 2.^(0:7));
    end
    cmdbytes(1) = 128 + offset + bitshift(ii-1, -8);
    cmdbytes(2) = mod(ii-1, 256);
    write(s, [255, cmdbytes, valbytes], 'uint8');
end

% read D back from RAM
if ~skipreadback
    s.flush();
    for ii = 1:1024
        cmdbytes(1) = offset + bitshift(ii-1, -8);
        cmdbytes(2) = mod(ii-1, 256);
        write(s, [255, cmdbytes, zeros(1,4)], 'uint8'); % read command
    end
    for ii = 1:1024
        rb = read(s, 6, 'uint8');

        cmdbytes(1) = offset + bitshift(ii-1, -8);
        cmdbytes(2) = mod(ii-1, 256);

        for iv = 1:4
            valbytes(iv) = sum(D(ii,(4-iv)*8 + (1:8)) .* 2.^(0:7));
        end
        
        if ~all(cmdbytes == rb(1:2))
            disp(["Command readback error at ii = " num2str(ii)]);
        end
        if ~all(valbytes == rb(3:6))
            disp(["Data readback error at ii = " num2str(ii)]);
        end
    end
end








