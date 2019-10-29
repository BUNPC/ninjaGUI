function cw6_toggleLasers(lasersOn, sp)

laserStr = sprintf('%s',dec2hex(2^32+lasersOn));
foos = sprintf('LASR %s\r\n',laserStr(2:end));
if strcmp(get(sp,'status'),'open')
    fprintf( sp, foos );
    pause(0.1);
end





