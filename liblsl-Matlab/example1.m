%%receiving data example

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
vec2=zeros(500,8);
t=zeros(1,500);
k=0;
while k<500
    k=k+1;
    % get data from the inlet
    [vec,ts] = inlet.pull_sample();
    
    vec2(k,:)=vec;
    t(k)=ts;
    % and display it
%     fprintf('%.2f\t',vec);
%     fprintf('%.5f\n',ts);
    
end
