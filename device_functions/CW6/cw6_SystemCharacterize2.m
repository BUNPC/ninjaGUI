function cw6_SystemCharacterize(obj,event,nSec)
global cw6info
global sp

%foo bars




%tt = get(obj,'TasksExecuted');
%cw6info.nRecords = tt;
%cw6info.time(tt) = tt;
tt = event
cw6info.nRecords = event;
cw6info.time(tt) = event;

SrcMap = cw6info.SD.SrcMap;


gainStates = cw6info.gainStates;
laserStates = cw6info.laserStates;

iState = 0;
for iGain = 1:length(gainStates)
%    fprintf( sp, sprintf('SETG 33 %d\r\n',gainStates(iGain)) );

    for iLaser = 1:length(laserStates)
        lasersOn = laserStates(iLaser);
        iState = iState + 1;
        [tt iLaser lasersOn iState]

        % turn lasers on
        cw6_toggleLasers( lasersOn, sp)
        pause(0.1)

        % Flush the data from the input buffer
        if get(sp,'BytesAvailable')>0
            fread( sp, get(sp,'BytesAvailable'), 'char' );
        end

        % start the recording
        fprintf( sp, sprintf('RUN_ \r\n'))
%        flush( sp );
    
%        flush( sp );
    
        % collect data for 1 second
        pause(nSec + .1);

        % read data and STOP cw6
        nWords = sp.BytesAvailable/4;%FcnCount/4;
        %    [nWords cw6info.WordsPerRecord*cw6info.recordRate]
        if nWords>=cw6info.WordsPerRecord*cw6info.recordRate*nSec
            a = fread( sp, cw6info.WordsPerRecord*cw6info.recordRate*nSec, 'float' ); %read cw6info.recordRate records
            a = reshape(a,[cw6info.WordsPerRecord cw6info.recordRate*nSec]);
            a(1:length(cw6info.SD.MeasListMask),:) = a(cw6info.SD.MeasListMask,:);
            cw6info.data(1:size(a,1),iState,tt) = mean(a,2);
            cw6info.dataStd(1:size(a,1),iState,tt) = std(a,[],2);
        else
            disp(sprintf('WARNING: Data not recorded (%d of %d)',nWords,cw6info.WordsPerRecord*cw6info.recordRate) );
        end
        pause(0.1)
        fprintf( sp, sprintf('STOP \r\n'))
        pause(0.1)

    end
end

cw6_toggleLasers( 0, sp)

figure(1)
imagesc(cw6info.data(:,:,tt),[0 100])


% figure(2)
% clf
% for ii=1:length(gainStates)
%     errorbar(cw6info.time(1:tt),squeeze(cw6info.data(12,1+(ii-1)*24,1:tt))',squeeze(cw6info.dataStd(12,1+(ii-1)*24,1:tt))')
%     hold on
% end
% hold off

     
