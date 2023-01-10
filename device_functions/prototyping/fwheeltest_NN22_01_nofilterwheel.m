initFW1

% Matlab helper functions for NN22_ControlBoard00
% 
% Initial version: 2023-1-5
% Bernhard Zimmermann - bzim@bu.edu
% Boston University Neurophotonics Center

% % optical powers for cal (@735nm)
% pw1 = [61.5e-6, 19e-6, 8.77e-6, 1.361e-6, 196.9e-9, 28.8e-9]-0.82e-9;
% pw2 = [61.5e-6, 33.2e-6, 5.64e-6, 0.353e-6, 83.7e-9, 1.93e-9]-0.695e-9;

% optical powers for cal (@730nm SMT730D/850D)
% pw1 = [2.859e-6, 0.945e-6, 0.49e-6, 99.3e-9, 17.89e-9, 3.22e-9]-0.052e-9;
% pw2 = [2.78e-6, 1.49e-6, 0.308e-6, 27.76e-9, 8.01e-9, 0.402e-9]-0.045e-9;

% optical powers for cal (@730nm) for new filter wheel
% pw1 = [5490 4490 3600 3020 2620 2160 1880 897 581 169 37.3 8.87];
% pw2 = [5490 3270 2700 2250 1962 958 630 203 40.5 9.88 1.705 0.782];

% optical powers for cal (@760nm NIRx) for new filter wheel
pw1 = [3150 2580 2072 1744 1523 1265 1099 532 348 117 27 6.87];
pw2 = [3150 1753 1523 1266 1101 531 347 124 27.2 6.96 1.82 0.929];
% pw2 = [2985 1671 1453 1208 1050 507 332 123.6 26 6.71 1.246 0.937];

% optical powers for cal (@850nm SFH4770S) for new filter wheel
% pw1 = [7805 6153 4589 3630 3530 2871 2437 1080 680 372 84 23];
% pw2 = [7791 3607 3521 2862 2424 1077  674  370  83  23  4  13];

% store actual ODs
set1 = log10(pw1(1)./pw1);
set2 = log10(pw2(1)./pw2);

% power at filter setting 0 0
pref = (31e-9/2)*2*(2.8/2)^2/(9.5/2)^2;

% fposset1=[1 2 3 4 7 8 9 10 11 12];
% fposset2=[1 2 4 6 7 8 9 10 11 12];

fposset1=[1 7 10 12];
fposset2=[1 4 7 10 12];


clear A;
clear R;
clear ods;

% reset filter wheels
% fprintf(fw2,'%s\r',['pos=' num2str(fposset2(1))]);
% fprintf(fw1,'%s\r',['pos=' num2str(fposset1(1))]);
pause(1);

rind = 1;

for fpos2=fposset2
    %fprintf(fw2,'%s\r',['pos=' num2str(fpos2)]);
    disp(fpos2)
    for fpos1=fposset1
        disp(fpos1)
        %fprintf(fw1,'%s\r',['pos=' num2str(fpos1)]);
        pause(3);
        for irep = 1:2 % additional measurements at each filter wheel setting
            ods(rind) = set1(fpos1) + set2(fpos2);
            disp(['fw1=' num2str(fpos1) ' fw2=' num2str(fpos2) ' od=' num2str(ods(rind))]);
            
            [A, stat] = collectDataNN22_01(stat);
    
            R(rind,:) = squeeze(A(:,1,8)-A(:,2,8));
    
            rind = rind +1;
            pause(0.1);
        end        
    end
end


% additional dark measurements
% fprintf(fw1,'%s\r',['pos=' num2str(12)]);
% fprintf(fw2,'%s\r',['pos=' num2str(12)]);
pause(3);
for idark = 1:16
    disp(['Dark ' num2str(idark) '/16']);
    ods(rind)=6.5;
    [A, stat] = collectDataNN22_01(stat);
    R(rind,:) = squeeze(A(:,1,8)-A(:,2,8));
    rind = rind +1;
    pause(0.1);
end

%%
save('.\meas\NN22_01_LED0A_med_8xOS_05.mat','R','ods','pref', 'stat');

%%
amps = mean(R,2);
[odss, ids] = sort(ods);
amps = amps(ids);

sigdark = sqrt(mean(amps(end-25:end).^2));
p = polyfit(odss(1:400),log10(amps(1:400)'),1);
odintersect = ((log10(sigdark)-p(2))/p(1));

figure(2);
semilogy(odss,abs(amps),'.');
hold on;
plot([odss(end), odintersect-0.5], sigdark.*[1 1],'Color',0.7*ones(1,3));
plot([odss(1) odintersect+0.5],[amps(1) 10^(p(1).*(odintersect+0.5)+p(2))],'Color',0.7*ones(1,3));
text(odintersect,sigdark,['\leftarrow NEP = ' num2str((pref*10^-odintersect)*1e15, 3) ' fW']);
ylabel('Digital level [a.u.]');
xlabel('Optical density');
grid on;