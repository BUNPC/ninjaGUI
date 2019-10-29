function ninja_FlushBuffer(s)

% Flush Buffer
ba = s.BytesAvailable;
while ba > 0
    fread(s,ba,'uchar');
    ba = s.BytesAvailable;
end