function ramb = genSingleSourceRAMB(isrc, comm_to_brd)
% Generate RAM B contents to collect data only from a single data souce.
%
% Initial version: 2023-3-21
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center

if nargin < 2
    comm_to_brd = false;
end

ramb = zeros(1024,32);

% set source selector bits (UART Rx Mux)
ramb(:, 1:6) = repmat(bitget(isrc-1, 1:6 ,'uint8'),1024,1);
% set flow enable bit (Uart Rx En)
ramb(2:end, 7) = 1;

if comm_to_brd
    % set flow enable bit also for initial state
    ramb(1, 7) = 1;
else
    % write end cycle bits (so that det card loads data into UART)
    ramb(10:500,10) = 1;
end