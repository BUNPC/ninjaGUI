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
buf = zeros(1,1024*(1+2+4));
rbbuf = zeros(1,1024*(1+2+4));

% write D to RAM
for ii = 1:1024
    for iv = 1:4
        valbytes(iv) = sum(D(ii,(iv-1)*8 + (1:8)) .* 2.^(0:7));
    end
    cmdbytes(2) = 128 + offset + bitshift(ii-1, -8);
    cmdbytes(1) = mod(ii-1, 256);
    buf(1, (ii-1)*7 + (1:7)) = [255, cmdbytes, valbytes];
end
write(s, buf, 'uint8');

% read D back from RAM
if ~skipreadback
    errcnt = 0;
    pause(0.1);
    s.flush();
    for ii = 1:1024
        cmdbytes(2) = offset + bitshift(ii-1, -8); % read command
        cmdbytes(1) = mod(ii-1, 256);
        buf(1, (ii-1)*7 + (1:7)) = [255, cmdbytes, zeros(1,4)]; 
    end
    write(s, buf, 'uint8');
    rbbuf = read(s, 1024*(1+2+4), 'uint8');
    for ii = 1:1024
        rb = rbbuf((1:7) + (ii-1)*7);

        cmdbytes(2) = offset + bitshift(ii-1, -8);
        cmdbytes(1) = mod(ii-1, 256);

        for iv = 1:4
            valbytes(iv) = sum(D(ii,(iv-1)*8 + (1:8)) .* 2.^(0:7));
        end
        if 240 ~= rb(1) || ~all(cmdbytes == rb(2:3)) || ~all(valbytes == rb(4:7))
            errcnt = errcnt +1;
        end
%         if 240 ~= rb(1)
%             disp(["RAM readback header error at ii = " num2str(ii)]);
%         end
%         if ~all(cmdbytes == rb(2:3))
%             disp(["RAM readback command error at ii = " num2str(ii)]);
%         end
%         if ~all(valbytes == rb(4:7))
%             disp(["RAM readback data error at ii = " num2str(ii)]);
%         end
    end
    if errcnt > 0
        disp(['RAM ' rselect ' readback errors at ' num2str(errcnt) ' locations.'])
    end
end








