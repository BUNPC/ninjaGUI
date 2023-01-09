%%
s = serialport("COM7", 6000000);
s.FlowControl = "hardware";

%%
% ar = [255 254 253 0 85 0 100 100 100 101 102 105 85 40 25 5 3 1 255 4 52];
if s.NumBytesAvailable > 0
    read(s, s.NumBytesAvailable, 'uint8'); % Flush
end
ar = randi(255,1,2000);
tic;
for ii = 1:100
    write(s,ar,"uint8");
    while s.NumBytesAvailable < length(ar)
        %pause(1e-3);
    end
    if ~all(read(s, length(ar), 'uint8') == ar)
        disp('Error');
    end
end
toc
disp('Done');