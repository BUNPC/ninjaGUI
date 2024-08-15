function result = StateSetup( app, srcram )
%StateSetupS The purpose of this function is to setup the state of the
%sources, detectors for the acquisition. Can be used to setup the
%frequencies of the LEDs, or the power levels if they are fixed, or the
%state sequences if there is temporal multiplexion


%hard code the states for now; I will have to find a convenient and
%compatible way to do

%2/7/23 update; currently the app will send an empty map, unless there is a
%stored map in the SD file somehow. Still hard coded here; I would
%recommend that somehow the state map for a given experiment is stored in
%the SD file for the experiment


stat = app.deviceInformation.stat; % DOES THIS WORK HERE? I need stat.s for initStat()

if isempty(srcram)
    srcram = convertSDtoSrcRAM( app.nSD ); 
    app.deviceInformation.srcram = srcram;
end

if ~srcram    % what does this do?
    srcram = app.deviceInformation.srcram;
    srcram(:,:,1:16) = 0; % power level zero
end

foo=find(srcram(1,:,32)==1);
nStates=foo(1);

fs=app.deviceInformation.stat.state_fs/nStates;
%initialize both RAMs

stat=initStat(stat, srcram);

%% Add the state map to the GUI variables for latter use

% for now I will save the statemap as a field of deviceInformation (other fields are the cfg file)


app.deviceInformation.Rate=fs;
app.editRate.Value=app.deviceInformation.Rate;

app.deviceInformation.stateIndices = mapToMeasurementList(app.deviceInformation.srcram,app.nSD.measList);

app.deviceInformation.subtractDark = 1;

%%
% save stat in the app variable

%submit to device
% done in initStat(). Doing it again just slows us down
% uploadToRAM( stat, stat.rama, 'a', false);
% uploadToRAM( stat, stat.ramb, 'b', false);
% for isrcb = 1:7
%     if stat.srcb_active(isrcb)
%         uploadToRAM(stat, squeeze(srcRAM(isrcb,:,:)), 'src', false, isrcb);
%     end
% end


stat = powerOn( stat );

app.deviceInformation.stat=stat;

result=1;
end

