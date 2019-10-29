function cw6_SystemCharacterize(obj,event)
global cw6info
global sp


fclose(sp)
set(sp,'BytesAvailableFcnCount',100000); %25 records/s, wpr words/record, 4 bytes/word
set(sp,'BytesAvailableFcnMode','byte');
%sp.BytesAvailableFcn = @readBytesAvailable;
sp.BytesAvailableFcn = @instrcallback;
fopen(sp); % connect


tt = get(obj,'TasksExecuted');
cw6info.nRecords = tt;
cw6info.time(tt) = tt;

SrcMap = cw6info.SD.SrcMap;

for iLaser = 1:18
    if iLaser<17
        lasersOn = bitset(0,SrcMap(iLaser),1);
    elseif iLaser==17
        lasersOn = 2^16-1;
    else
        lasersOn = 0;
    end
    [tt iLaser lasersOn]

    % turn lasers on
    toggleLasers( lasersOn, sp)
    pause(0.1)

    % Flush the data from the input buffer
    if get(sp,'BytesAvailable')>0
        fread( sp, get(sp,'BytesAvailable'), 'char' );
    end
    
    % start the recording
    fprintf( sp, sprintf('RUN_ \r\n'))

    % collect data for 1 second
    pause(1.5);

    % read data and STOP cw6
    nWords = sp.BytesAvailable/4;%FcnCount/4;
%    [nWords cw6info.WordsPerRecord*25]
    if nWords>=cw6info.WordsPerRecord*25
        a = fread( sp, cw6info.WordsPerRecord*25, 'float' ); %read 25 records
        a = reshape(a,[cw6info.WordsPerRecord 25]);
        a(1:length(cw6info.SD.MeasListMask),:) = a(cw6info.SD.MeasListMask,:);
        cw6info.data(1:size(a,1),iLaser,tt) = mean(a,2);
        cw6info.dataStd(1:size(a,1),iLaser,tt) = std(a,[],2);
    else
        disp('WARNING: Data not recorded' );
    end
    pause(0.1)
    fprintf( sp, sprintf('STOP \r\n'))
    pause(0.1)
    
end

toggleLasers( 0, sp)

figure(1)
imagesc(cw6info.data(:,:,tt),[0 100])


figure(2)
errorbar(cw6info.time(1:tt),squeeze(cw6info.data(9,1,1:tt))',squeeze(cw6info.dataStd(17,1,1:tt))')
hold on
errorbar(cw6info.time(1:tt),squeeze(cw6info.data(9,18,1:tt))',squeeze(cw6info.dataStd(23,7,1:tt))')
hold off

     
