function snirf1 = convertBintoSnirfv2( fName, flagSave )

if ~exist('flagSave')
    flagSave = 0;
end

% load bin file
fID=fopen([fName,'.bin']);
inputBytes=fread(fID,'uint8');
fclose(fID);

% load sidecar file
load([fName,'_stateMap.mat']);

% load snirf file
SD = nSD;

subtractDark=1; % make it as 1 to subtract dark state

foo=find(stateMap(:,27)==1);
nStates=foo(1);
fs=devInfo.state_fs/nStates;
acc_active=devInfo.acc_active;
aux_active=devInfo.aux_active;
N_DETECTOR_BOARDS =devInfo.N_DETECTOR_BOARDS;
stat_n_smp = devInfo.stat.n_smp;
[B, unusedBytes, avgDet, Auxdata, TGAdata, info] = translateNinja2022Bytesv3_BZ20230817(inputBytes,stateMap,N_DETECTOR_BOARDS,acc_active,aux_active);
B=circshift(B,-1,3);

disp( sprintf('Lost %d states amongst the %d that were recorded (%.1f%%)',length(info.lstGaps),length(info.estados),length(info.lstGaps)/(length(info.lstGaps)+length(info.estados)) ) )

% normslize data to mskr values between 0 and 1
%B = B./(app.deviceInformation.stat.n_smp*(2^15-1));
B = B./(stat_n_smp*(2^15-1));

% 
%indices=mapToMeasurementList_DualPower(stateMap,SD.MeasList);
indices = stateIndices;

organizedData=nan(size(B,1),size(SD.MeasList,1));
organizedDataDark=nan(size(B,1),size(SD.MeasList,1));
% for loop is likely not the best way to do it

nStates=size(B,3);
cumDark=0;
for ki=1:size(SD.MeasList,1)    
    organizedData(:,ki)=B(:,indices(ki,2),indices(ki,1));        
    organizedDataDark(:,ki)=B(:,indices(ki,2),indices(ki,3));
    if subtractDark
%            darkState=B(:,indices(ki,2),indices(ki,1)+1);
%        darkState=B(:,indices(ki,2),indices(ki,3));
        %subtracts the adjacent state (after the current). Assumes
        %there is a dark state between each active state
        organizedData(:,ki)=organizedData(:,ki)-organizedDataDark(:,ki);
        cumDark=cumDark+mean(organizedDataDark(:,ki));
    end
end

organizedData(organizedData<0)=1e-6;

t=(0:size(organizedData,1)-1)./fs;
temp1=sum(~isnan(organizedData)); 


% temp1=temp1(temp1>4);     
indi=1:median(temp1)-1; 
t=t(indi)';
d=organizedData(indi,:);
dDark=organizedDataDark(indi,:);
ml=SD.MeasList;

snirf1=SnirfClass(struct( ...
                'd',d, ...
                't',t, ...
                'SD',SD, ...
                'ml',ml ...
                )); 
snirf1.metaDataTags = MetaDataTagsClass();
snirf1.metaDataTags.tags.TimeUnit = 's';
if ~isempty(Auxdata)
%    Auxdata = Auxdata(1:floor(size(Auxdata,1)/size(d,1)):end,:);
%    if size(Auxdata,1) > length(t)
%        Auxdata = Auxdata(1:length(t),:);
%    end
    t_aux = [1:size(Auxdata,1)]'/devInfo.state_fs;

    aux_obj_digital = AuxClass(Auxdata(:,1),t_aux,'digital');
    aux_obj_analog1 = AuxClass(Auxdata(:,2),t_aux,'analog-1');
    aux_obj_analog2 = AuxClass(Auxdata(:,3),t_aux,'analog-2');
    aux_obj_dark    = AuxClass(dDark,t,'dark signal');
    snirf1.aux = [aux_obj_digital aux_obj_analog1 aux_obj_analog2 aux_obj_dark];
end

if acc_active
    t_acc =  [1:size(Auxdata,1)]'/devInfo.state_fs;
    temp_obj = AuxClass(TGAdata(:,1),t_acc,'temperature');
    gyro_data = TGAdata(:,2:4)*devInfo.stat.gyrofs;
    gyro_obj = AuxClass(gyro_data,t_acc,'gyroscope');
    acc_data = TGAdata(:,5:7)*devInfo.stat.accfs;
    acc_obj = AuxClass(acc_data,t_acc,'accelerometer');
    snirf1.aux = [snirf1.aux temp_obj gyro_obj acc_obj]; 
end

if flagSave
    [folder, baseFileNameNoExt, extension] = fileparts(fName);
    snirf1.Save([folder baseFileNameNoExt '.snirf'])
%    snirf1.Save([folder filesep baseFileNameNoExt '.snirf'])
end