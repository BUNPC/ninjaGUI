function fNIRS1k_FlushBuffer(s)
%% Just a basic call to flush the data buffer
% Flush Buffer
ba = s.BytesAvailable;
while ba > 0
    fread(s,ba,'uchar');
    ba = s.BytesAvailable;
end