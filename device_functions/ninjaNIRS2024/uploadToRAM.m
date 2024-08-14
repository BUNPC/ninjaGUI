% Matlab helper functions for NN22_ControlBoard00
% 
% Initial version: 2022-12-30
% Revision for VCCS: 2024-7-18
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center

function uploadToRAM(stat, D, ram_sel, skipreadback, brd_sel)

% Dimensions of D should be 1024x32
% RAM sizes are:
% a: 1024x9
% b: 1024x18
% src: 1024x32
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
if nargin < 5
    brd_sel = 0;
end

if ram_sel == 'a'
    offset = 16;
    data_relay = false;
    ram_rb_hdr = 240;
elseif ram_sel == 'b'
    offset = 32;
    data_relay = false;
    ram_rb_hdr = 240;
elseif ram_sel == "src" %|| ram_sel == "det"
    offset = 48;
    data_relay = true;
    ram_rb_hdr = 255;
    % select correct board for UART relay
    uploadToRAM(stat, genSingleSourceRAMB(brd_sel +32, true), 'b', true);
else
    error('ram_select invalid');
end

% flush FSM
write(stat.s, zeros(1,8), 'uint8');

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
if data_relay % slow down transmission
    % uart to plug in boards is only half as fast as main uart to fpga
    for iseg = 1:8
        write(stat.s, buf( (iseg-1)*128*7 + (1:(128*7)) ), "uint8");
        pause(0.01);
    end
else % full speed
    write(stat.s, buf, "uint8");
end

% read D back from RAM
if ~skipreadback
    errcnt = 0;
    pause(0.1);
    stat.s.flush();
    for ii = 1:1024
        cmdbytes(2) = offset + bitshift(ii-1, -8); % read command
        cmdbytes(1) = mod(ii-1, 256);
        buf(1, (ii-1)*7 + (1:7)) = [255, cmdbytes, zeros(1,4)]; 
    end

    if data_relay % slow down transmission
        % uart to plug in boards is only half as fast as main uart to fpga
        for iseg = 1:8
            write(stat.s, buf( (iseg-1)*128*7 + (1:(128*7)) ), "uint8");
            rbbuf( (iseg-1)*128*7 + (1:(128*7)) ) = read(stat.s, 128*(1+2+4), 'uint8');
        end
    else % full speed
        write(stat.s, buf, 'uint8');
        rbbuf = read(stat.s, 1024*(1+2+4), 'uint8');
    end

    % verify data read back
    for ii = 1:1024
        rb = rbbuf((1:7) + (ii-1)*7);

        cmdbytes(2) = offset + bitshift(ii-1, -8);
        cmdbytes(1) = mod(ii-1, 256);

        for iv = 1:4
            valbytes(iv) = sum(D(ii,(iv-1)*8 + (1:8)) .* 2.^(0:7));
        end
        if ram_rb_hdr ~= rb(1) || ~all(cmdbytes == rb(2:3)) || ~all(valbytes == rb(4:7))
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
        disp(['RAM ' ram_sel ' readback errors at ' num2str(errcnt) ' locations.'])
    end
end

if isfield(stat,'ramb') && ram_sel == "src" %|| ram_sel == "det"
    % restore original ramb contents
    uploadToRAM(stat, stat.ramb, 'b', false);
end








