%%function that plots the samples being pushed to LSL

fs=200;
ndata=fs;
tspan=10; %visualization span in seconds

%% initialize LSL
% instantiate the library
disp('Loading library...');
lib = lsl_loadlib();

% make a new stream outlet
disp('Creating a new streaminfo...');
info = lsl_streaminfo(lib,'SimpleStream1','EEG',ndata,100,'cf_float32','sdfwerr32432');

disp('Opening an outlet...');
outlet = lsl_outlet(info);

% send data into the outlet, sample by sample


disp('Now transmitting data...');


%% initialize stuff

fname=['experiment',num2str(datestr(now,'HH-MM-SS.FFF')),'.txt'];
fID = fopen(fname,'a');

Nsamples=tspan*fs;
x=zeros(1,Nsamples);
t=linspace(-10,0,Nsamples);
tic;
tcur=toc;
%% main loop

while 1
    datos=randn(1,ndata);
    outlet.push_sample(datos);
    

    pause(1);
    tcur=toc;
    x=circshift(x,-ndata);
    x(end-ndata+1:end)=datos;
    
    t=circshift(t,-ndata);
    ttemp=linspace(tcur-1,tcur,ndata);
    t(end-ndata+1:end)=ttemp;
    
    %fprintf(fID,'%6s %12s \n',ttemp',datos');
    fprintf(fID, '%5.4f,%5.4f\r\n', [ttemp;datos]);
    
    %t=[t,linspace(t(end),tcur,ndata)];    
    %plot(t(2:end),x)
    %
    plot(t,x)
    xlim([t(end)-10,t(end)])
    drawnow
end

fclose(fID);
