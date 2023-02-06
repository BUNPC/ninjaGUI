function SNR=SNR1Hz(x,fs)
%Calculates signal to noise ratio for an fNIRS signal
%in this case, SNR is calculted as follows. Signal is defined as the DC
%power plus the 1 Hz band. Noise is the variance of everything else.

[pow,f]=pwelch(x,[],[],[],fs);
totalPower=trapz(f,pow);
[pow,f]=pwelch(detrend(x),[],[],[],fs);
ACPower=trapz(f,pow);
DCPower=totalPower-ACPower;

Deltaf=0.3;  %say this is the variability of cardiac rate
f1HzBandIndi=(f>=(1-Deltaf))&(f<(1+Deltaf));


Band1HzPower=trapz(f(f1HzBandIndi),pow(f1HzBandIndi));
Signal=Band1HzPower;
%Noise=ACPower-Band1HzPower+DCPower;
Noise=ACPower-Band1HzPower;

SNR=Signal/Noise;
% 
% [pow1,f]=pwelch(x,[],[],[],fs);
% 
% [pow2,f]=pwelch(x-mean(x),[],[],[],fs);
% 
% [pow3,f]=pwelch(detrend(x),[],[],[],fs);
% 
% loglog(f,pow1,f,pow2,f,pow3)
% legend('Raw','Mean subtraction','Detrend')