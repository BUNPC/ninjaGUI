function status=fNIRS1k_Ask4Status(app)
% Queries the status of the device. Right now it doesn't actually query
% anything, it's just used as an excuse to to initialize the detectors

% disp('Querying fNIRS1000 status...')

CMDSTRING = [254 0 0 0 0 255-255 255-255 0 0 1];
fwrite(app.sp,CMDSTRING);
status=1;


% N_WORDS_PER_DFT = 2;
% N_BYTES_IN_DFT_WORD = 5;
% N_FREQ = 8;
% 
% N_BYTES_TO_READ_PER_SAMPLE = N_WORDS_PER_DFT * N_BYTES_IN_DFT_WORD * (N_FREQ+1) +3; % N_FREQ+1 : for max/avg data; +3 for [channel, #bytes, DFT count]
%raw = fread(app.sp,N_BYTES_TO_READ_PER_SAMPLE,'uchar');
 
 
% N_WORDS_PER_DFT = 2;
% N_BYTES_IN_DFT_WORD = 5;
% N_FREQ = 8;
% 
% N_BYTES_TO_READ_PER_SAMPLE = N_WORDS_PER_DFT * N_BYTES_IN_DFT_WORD * (N_FREQ+1) +3; % N_FREQ+1 : for max/avg data; +3 for [channel, #bytes, DFT count]
% 
% trycnt=5;
% 
% while trycnt
%     
%     fwrite(app.sp,CMDSTRING);
%     pause(0.01)
% 
%     
%     raw = fread(s,N_BYTES_TO_READ_PER_SAMPLE,'uchar');
%     
%     
%      if raw(1) == 254
%             ba_inst = sum(raw(2:3) .* 256.^(0:1)'); 
%             disp(['Status: bytes available: instrument = ' num2str(ba_inst,'%05d') ' host = ' num2str(s.BytesAvailable,'%05d') '  values received ' num2str(s.ValuesReceived)]);
%             continue;
%      else
%          disp('Unexpected data format received, trying again')
%      end
%      
%      trycnt=trycnt-1;
% end
% 
% status=0;
% disp('Could not get status of device ')




