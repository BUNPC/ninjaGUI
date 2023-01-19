
N=10; %number of seconds to acquire per
R=10; %number of repetitions per time point
tiempos=(150:50:500)*1e-6;
tiempos=(150:50:450)*1e-6;
DLThreshold=1e1;  %threshold to count mean signal level as on

%% create buffers
byteStreams=cell(R,length(tiempos));
chansOnPerState=zeros(length(tiempos),16);

%% start
for kii=1:length(tiempos)
    disp(['Time ',num2str(tiempos(kii))])
    for ki=1:R
        disp(['Repetition ',num2str(ki)])
        %% connect to device
        stat = initStat1(tiempos(kii));

        %% upload state definitions and power on; NOTE: MAKE SURE YOU UNDERSTAND THE POWER ON AND POWER OFF SEQUENCE AND HOW IT RELATES TO CREATING/CONNECTING THE DEVICE
        uploadToRAM(stat.s, stat.rama, 'a', false);
        uploadToRAM(stat.s, stat.ramb, 'b', false);
        stat = powerOn(stat);

        %% Reset program counters (probably just equivalent to a flush buffer operation)

        stat=ResetCounters(stat);

        %% start acquisition
        disp('starting acquisition')
        stat=StartAcquisition(stat);


        %% acquire for N seconds

        pause(N)

        %% read bytes available
        A=read(stat.s, stat.s.NumBytesAvailable, 'uint8');

        %% stop acquisition


        stat.run = false;
        stat = updateStatReg(stat);

        % Q: what if I want to stop the device and turn it on again later? what is
        % the sequence


        %% translate bytestream to readable data
        [B,unusedBytes]=translateNinja2022Bytes(A);
        Nstates=size(B,3);
        fs=1e3/Nstates;

        %% close device
        clear stat

        %% find how many channels were above noise level
        medias=squeeze(nanmean(B,1));
        chansOnPerState(kii,:)=chansOnPerState(kii,:)+circshift(sum(medias>DLThreshold),-1);

        %% store bytestream for future reference
        byteStreams{ki,kii}=A;

        %% repeat
    end
end
% save('experimentHoldoff1.mat','byteStreams')

% %% plot
%
figure(1)
plotN=ceil(sqrt(Nstates));

t=((1:length(B))-1)/fs;

tiledlayout(plotN,plotN);

limites=[1,1.1*max(B(:))];

for ki=1:Nstates
    nexttile
    semilogy(t,B(:,:,ki))
    ylim(limites)
    xlim([0,max(t)])
    title(num2str(ki-1))
end

% %%
% figure(2)
% semilogy(t,B(:,2,2))


