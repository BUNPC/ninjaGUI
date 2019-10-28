%%receiving data example display

%% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG'); end
% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

disp('Now receiving data...');
N=100000;
x=zeros(1,N)*NaN;
t=x*NaN;

tic;
tcur=toc;
dcount=0;
while true
%     k=k+1;
    % get data from the inlet
    [vec,ts] = inlet.pull_sample();
    ndata=length(vec);
    tprev=tcur;
    tcur=toc;
     
    t=circshift(t,-ndata);
    ttemp=linspace(tprev,tcur,ndata);
    t(end-ndata+1:end)=ttemp;
    %t=[t,ts];
    x=circshift(x,-ndata);
    x(end-ndata+1:end)=vec;
    figure(1)
    plot(t,x)
    xlim([t(end)-10,t(end)])
    drawnow
    
    if floor(t(end)/10)>dcount
        dcount=dcount+1;
        figure(2)
        histogram(x)
        title('Histrogam of data buffer')
    end
    
%     
%     vec2(k,:)=vec;
%     t(k)=ts;
%     % and display it
% %     fprintf('%.2f\t',vec);
% %     fprintf('%.5f\n',ts);
%     
end


% 
% vec2=zeros(500,8);
% t=zeros(1,500);
% k=0;
% while k<500
%     k=k+1;
%     % get data from the inlet
%     [vec,ts] = inlet.pull_sample();
%     
%     vec2(k,:)=vec;
%     t(k)=ts;
%     % and display it
% %     fprintf('%.2f\t',vec);
% %     fprintf('%.5f\n',ts);
%     
% end
