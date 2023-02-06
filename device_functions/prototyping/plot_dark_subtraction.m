dK=2;

load unobstructed.mat

fs=1/mean(diff(t));


figure(1)
plotN=ceil(sqrt(Nstates));

t=((1:length(B))-1)/fs;

tiledlayout(plotN,plotN);

limites=[1,1.1*max(B(:))];

for ki=1:Nstates-1
    nexttile
    semilogy(t,B(:,:,ki)-B(:,:,ki+1))
    ylim(limites)
    xlim([0,max(t)])
    title(num2str(ki-1))
end

figure(2)

kii=3;
ki=4;
SNR1Hz(B(:,kii,ki),fs);

for ki=4    
    toPlot=B(:,kii,ki)-B(:,kii,ki+1);
    semilogy(t,toPlot)       
    xlim([0,max(t)])
    title('Unobstructed, dark subtracted, IR channel 3')
end
SNR1Hz(toPlot,fs);

%%
kii=3;
ki=4;
figure(3)
subplot(2,1,1)
toPlot=detrend(B(:,kii,ki),dK);
plot(t,toPlot)
title('Unobstructed, IR channel 3')


subplot(2,1,2)
[pow,f1]=pwelch(toPlot,[],[],[],fs);
semilogy(f1,pow)
xlabel('Frequency [Hz]')
ylabel('Power density (detrended signal)')

S=SNR1Hz(B(:,kii,ki),fs);
sgtitle(['SNR = ',num2str(S)])

%% 
kii=3;
ki=4;

figure(5)
subplot(2,1,1)
for ki=4
    kii=3;
    toPlot=detrend(B(:,kii,ki)-B(:,kii,ki+1),dK);
    plot(t,toPlot)       
    xlim([0,max(t)])
    title('Unobstructed, dark subtracted, IR channel 3')
    xlabel('Time [s]')
end

subplot(2,1,2)
[pow,f1]=pwelch(toPlot,[],[],[],fs);
semilogy(f1,pow)
xlabel('Frequency [Hz]')
ylabel('Power density (detrended signal)')

S=SNR1Hz(toPlot,fs);
sgtitle(['SNR = ',num2str(S)])

%% 
kii=3;
ki=4;

figure(6)
subplot(2,1,1)
for ki=4
    kii=3;
    toPlot=detrend(-B(:,kii,ki-1)/2+B(:,kii,ki)-B(:,kii,ki+1)/2,dK);
    plot(t,toPlot)       
    xlim([0,max(t)])
    title('Unobstructed, dark filtered, IR channel 3')
    xlabel('Time [s]')
end


subplot(2,1,2)
[pow,f1]=pwelch(toPlot,[],[],[],fs);
semilogy(f1,pow)
xlabel('Frequency [Hz]')
ylabel('Power density (detrended signal)')
S=SNR1Hz(-B(:,kii,ki-1)/2+B(:,kii,ki)-B(:,kii,ki+1)/2,fs);
sgtitle(['SNR = ',num2str(S)])

%%
load obstructed.mat

figure(11)
plotN=ceil(sqrt(Nstates));

t=((1:length(B))-1)/fs;

tiledlayout(plotN,plotN);

limites=[1,1.1*max(B(:))];

for ki=1:Nstates-1
    nexttile
    semilogy(t,B(:,:,ki)-B(:,:,ki+1))
    ylim(limites)
    xlim([0,max(t)])
    title(num2str(ki-1))
end

ki=4;
    kii=3;
SNR1Hz(B(:,kii,ki),fs);
figure(12)

for ki=4
    kii=3;
    toPlot=detrend(B(:,kii,ki)-B(:,kii,ki+1),dK);
    plot(t,toPlot)   
    xlim([0,max(t)])
    title('Obstructed, dark subtracted, IR channel 3')
end
SNR1Hz(toPlot,fs);

kii=3;
ki=4;
figure(13)
fs=1/mean(diff(t));
toPlot=detrend(B(:,kii,ki),dk);
subplot(2,1,1)
plot(t,toPlot)    
title('Obstructed, IR channel 3')
subplot(2,1,2)
[pow,f1]=pwelch(toPlot,[],[],[],fs);
semilogy(f1,pow)
xlabel('Frequency [Hz]')
ylabel('Power density (detrended signal)')
S=SNR1Hz(B(:,kii,ki),fs);
sgtitle(['SNR = ',num2str(S)])



kii=3;
ki=4;

figure(15)
subplot(2,1,1)
for ki=4
    kii=3;
    toPlot=detrend(B(:,kii,ki)-B(:,kii,ki+1),dK);
    plot(t,toPlot)       
    xlim([0,max(t)])
    title('Obstructed, dark subtracted, IR channel 3')
    xlabel('Time [s]')
end


subplot(2,1,2)
[pow,f1]=pwelch(toPlot,[],[],[],fs);
semilogy(f1,pow)
xlabel('Frequency [Hz]')
ylabel('Power density (detrended signal)')
S=SNR1Hz(toPlot,fs);
sgtitle(['SNR = ',num2str(S)])


figure(16)
subplot(2,1,1)
for ki=4
    kii=3;
    toPlot=detrend(-B(:,kii,ki-1)/2+B(:,kii,ki)-B(:,kii,ki+1)/2,dK);
    plot(t,toPlot)    
    xlim([0,max(t)])
    title('Obstructed, dark filtered, IR channel 3')
    xlabel('Time [s]')
end

subplot(2,1,2)
[pow,f1]=pwelch(toPlot,[],[],[],fs);
semilogy(f1,pow)
xlabel('Frequency [Hz]')
ylabel('Power density (detrended signal)')

S=SNR1Hz(-B(:,kii,ki-1)/2+B(:,kii,ki)-B(:,kii,ki+1)/2,fs);
sgtitle(['SNR = ',num2str(S)])