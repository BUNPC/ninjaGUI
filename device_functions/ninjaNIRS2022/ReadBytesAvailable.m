function [dataoutput,packlen,remainderbytes,datac,statusdata,maxvout,avgvout]=ReadBytesAvailable(app)
% Used to read the data sent from the instrument and translate it to a a
% matlab array. The only input is app, which is the structure containing
% the GUI variables. The specific implementation of this function will use
% whichever app properties are useful or necessary to calculate the
% required outputs
% The required outputs for this functions to interact
% correctly with the GUI are:
% dataoutput is the data of the fNIRS and aux channels: channels in the
% array need to be sorted the same was as in the measurement list
% packlen says how many samples were collected for each channel;
% this could be a scalar if all channels acquired the same number of
% channels in the iteration, but in general is an array in which each
% element specifies how many samples were acquired at each channel and
% wavelength
% remainderbytes needs to contain the bytes that were read but not used in
% the current iteration because if the data read operation did not return a
% discrete number of data packages. This way they can be appended to the
% start of the bytestream read in the next read opperation

% optional outpus (the GUI won't break if they are not returned)
% datac contains the complex data of all channels if available; this was
% something that was proposed for frequency multiplexed systems, but in the
% end we have not used it and the GUI does nothing to these data
% statusdata contains the information in the status data packages, if
% available; but the GUI currently does nothing with them
% maxvout returns the maximum value for each optode. avgout returns the
% average value for each optode; these two can be used for saturation
% purposes. avgout must be returned if the hardware configuration specifies
% that the hardware is able to measure and display through the GUI which
% optodes are saturared (field 'optodeSaturationThreshold' from the config
% file)

%% parse app variables

s=app.sp; %serial port
dev=app.deviceInformation; %config file
SD=app.nSD; %probe file
prevrbytes=app.rbytes; %remainder bytes from the previous read operation
fID=app.fstreamID;  %file streamer for debug mode; this can be used to stream the bytes directly to file as a backup

%% read serial buffer opperations.
% It is setup so the read operation reads all bytes available in the serial
% buffer; however, there needs to be a minimum amount of bytes in the
% buffer for the operation to be performed; if there is less than some
% number of bytes, the function will end with no read operations and the
% bytes will be read in the next iteration. This is so the function is not
% called multiple times to read just one byte, which I think makes
% acquisition more efficient
ba=s.NumBytesAvailable;

rb=300; %minimum number of bytes to read per operation

if ba>rb
    raw = read(s,ba,'uint8')';
    if ~isempty(fID)
        fwrite(fID,raw,'uchar');
    end
else
    dataoutput=[];
    maxvout=[];
    avgvout=[];
    packlen=0;
    datac=[];
    statusdata=[];
    remainderbytes=prevrbytes;
    return;
end

raw=[prevrbytes;raw];
rawN=size(raw,1);

%% translate data to a numeric array
[B,unusedBytes]=translateNinja2022Bytes(raw);
Nstates=size(B,3);
fs=1e3/Nstates;

% B is organized as time by detector by state; for this implementation, the
% subfunction to translate the bytes needs to handle things like the not
% getting the same number of samples for each 
% The first dimension of B will be number of samples acquired for the
% channel with more samples in this read operation. second dimnstion is the
% number of detectors. Third dimension are the states. Unacquired samples
% will be stored as nan values


%% code to go from detector and state number to measurments of the measurement list


%% prepare output variables


% %% hardware constants
% N_OPTODES=dev.nDets;
% N_WORDS_PER_DFT = 2;
% N_BYTES_IN_DFT_WORD = 5;
% N_FREQ = 8;
% N_AUX = dev.nAux;
% N_BYTES_PER_AUX = 2;
% N_ONBOARD_AUX=2;  %the current firmware has 2 AUX on board, the rest are remote
% 
% N_BYTES_TO_READ_PER_SAMPLE=N_WORDS_PER_DFT * N_BYTES_IN_DFT_WORD * (N_FREQ+1) +5; % N_FREQ+1 : for max/avg data; +3 for [channel, #bytes, DFT count];
% 
% %% DFT constants and data offsets
% 
% DFT_N=1024;
% KD = [56 60 64 70 80 84 96 105]; % demodulation k
% 
% offsetA = (0:N_FREQ-1)*N_BYTES_IN_DFT_WORD*N_WORDS_PER_DFT +3;
% offsetB=offsetA+N_BYTES_IN_DFT_WORD;
% wordpos=1:N_BYTES_IN_DFT_WORD;
% part1=wordpos+offsetA';
% part2=wordpos+offsetB';
% part3=max(part2(:));
% part4=part3 + N_BYTES_IN_DFT_WORD;
% powso256=256.^(0:N_BYTES_IN_DFT_WORD-1);
% Kernel=exp(-1i*(2*pi/DFT_N)*KD(1:N_FREQ));
% 
% %% read bytes available as a multiple of bytes in the buffer and number of optodes (and aux)
% ba=s.NumBytesAvailable;
% 
% %this code helps prevent reading incomplete data packages
% npacks=30;   %making this constant larger means we read more packets at a time, reducing processing overhead, but making it too large will affect refresh rate
% rb=floor(ba/N_BYTES_TO_READ_PER_SAMPLE/(N_OPTODES+1)/npacks)*N_BYTES_TO_READ_PER_SAMPLE*(N_OPTODES+1)*npacks;
% 
% if rb>0
%     raw = read(s,rb,'uint8')';
%     if ~isempty(fID)
%         fwrite(fID,raw,'uchar');
%     end
% else
%     dataoutput=[];
%     maxvout=[];
%     avgvout=[];
%     packlen=0;
%     datac=[];
%     statusdata=[];
%     remainderbytes=prevrbytes;
%     return;
% end
% 
% raw=[prevrbytes;raw];
% rawN=size(raw,1);
% 
% 
% %% find indicator bytes
% indicator=find(raw==N_BYTES_TO_READ_PER_SAMPLE-2);
% indicator=indicator((indicator+N_BYTES_TO_READ_PER_SAMPLE-2)<=rawN); %only consider  potentially complete packages
% packC=indicator-1;   %potential initial positions of data packets
% packC(packC==0)=[];  %this means we missed the initial byte of one data packet
% 
% %% now, segregate candidate packages on data, aux or status
% 
% pAuxp=packC(raw(packC)==200); %possible aux positions
% pRemp=packC(raw(packC)==201); %possible remote board positions
% pStatp=packC(raw(packC)==254); %possible Status positions
% pDatap=packC(raw(packC)>=0&raw(packC)<N_OPTODES); %possible detector positions
% 
% 
% %% now look for the stop bytes; if they don't have them, then they are not data packages
% %these are way more likely to be the actual positions of the data packages
% pAux=pAuxp(raw(pAuxp+N_BYTES_TO_READ_PER_SAMPLE-2,:)==171&raw(pAuxp+N_BYTES_TO_READ_PER_SAMPLE-1,:)==171);
% pStatp=pStatp(raw(pStatp+N_BYTES_TO_READ_PER_SAMPLE-2,:)==172&raw(pStatp+N_BYTES_TO_READ_PER_SAMPLE-1,:)==172);
% pDatap=pDatap(raw(pDatap+N_BYTES_TO_READ_PER_SAMPLE-2,:)==170&raw(pDatap+N_BYTES_TO_READ_PER_SAMPLE-1,:)==170);
% pRemp=pRemp(raw(pRemp+N_BYTES_TO_READ_PER_SAMPLE-2,:)==170&raw(pRemp+N_BYTES_TO_READ_PER_SAMPLE-1,:)==170);
% 
% 
% 
% %% initialize databuffer
% ML=SD.measList;
% 
% maxsampN=ceil(length(pDatap)/N_OPTODES)+3; %max number of samples possibly contained in the data package
% datac=complex(nan(N_OPTODES,maxsampN,N_FREQ)); %complex data buffer
% auxb=nan(N_ONBOARD_AUX,maxsampN);  %aux data buffer
% auxrem=nan(N_AUX-N_ONBOARD_AUX,maxsampN); %placeholder for the remote trigger auxiliaries
% 
% data=nan(size(ML,1),maxsampN); %buffer for intensity data
% 
% 
% %% decode the optode data packets
% databm=complex(nan(maxsampN,N_FREQ));
% maxdatapackpos=0;
% maxvout=nan(N_OPTODES,size(databm,1));
% avgvout=nan(N_OPTODES,size(databm,1));
% for k=0:N_OPTODES-1
%     indik=pDatap(raw(pDatap)==k);  %contain the indices of the potential data packages on raw for optode k
%     seqk=raw(min(indik+2,end));  %contains the sequence data of potential data package; real data packages should be on a consecutive sequence
%     
%     dseqk=diff(seqk);
%     sbreaks=find(dseqk~=1&dseqk~=-255); %sequence breaks
%     if dseqk(1)==1  
%         sbreaks=sbreaks(2:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
%     else
%         %in the unlikely case the first packet was the sequence breaking one
%         sbreaks=sbreaks(1:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
%     end
%     
%     dataindk=indik;
%     dataindk(sbreaks)=[];  %remove the sequence breaking packages
%     
%     
%     maxdatapackpos=max(max(maxdatapackpos),max(dataindk)); %this variable will be used to find where the unused bytes are, so we can use them next iteration
%     
%     %the previous code is also potentially losing the last data point, but
%     %1) doing that prevents errors, 2) it also prevents errors in the
%     %likely case that it was truncated
%     
%     
%     %% now, for each element of dataindk...
%     mLength=size(dataindk,1);
%     databm=databm*nan;
%     for m=1:mLength
%         %% I need to actually convert the data package to intensity data
%         indi1=dataindk(m):(dataindk(m)+N_BYTES_TO_READ_PER_SAMPLE-1); %indices for package
%         if all(indi1<=rawN)  %this check is to avoid incomplete data packages
%             rawp=raw(indi1,:);
%             %transform raw data to complex FT
%             pnm1=sum(rawp(part1).*powso256,2)';
%             indi=pnm1>(2^39-1);
%             pnm1(indi)=pnm1(indi)-2^40;
%             pnm0=sum(rawp(part2).*powso256,2)';
%             indi=pnm0>(2^39-1);
%             pnm0(indi)=pnm0(indi)-2^40;
%             databm(m,:)=pnm0 - Kernel.*pnm1;
%             try
%                 maxvout(k+1,m)=sum(rawp((1:N_BYTES_IN_DFT_WORD) + part3).* powso256');
%                 avgvout(k+1,m) = sum(rawp((1:N_BYTES_IN_DFT_WORD) + part4).* powso256')/DFT_N;             
%             catch ME
%                 disp(ME.message)
%             end
%         end
%     end
%     datac(k+1,:,:)=databm;
% end
% 
% %% now decode the aux data packets
% 
% %discard incomplete aux packets
% pAux(pAux+2>rawN)=[];
% 
% 
% seqAux=raw(pAux+2);  %contains the sequence data of potential aux packets
% dseqAux=diff(seqAux);
% sbreaks=find(dseqAux~=1&dseqAux~=-255); %sequence breaks
% 
% if dseqAux(1)==1  
%         sbreaks=sbreaks(2:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
%     else
%         %in the unlikely case the first packet was the sequence breaking one
%         sbreaks=sbreaks(1:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
% end
% 
% pAux(sbreaks)=[]; %remove the sequence breaking packages from consideration
% 
% pows256b=256.^(0:N_BYTES_PER_AUX-1)';
% for m=1:length(pAux)
%     indi1=pAux(m):pAux(m)+N_BYTES_TO_READ_PER_SAMPLE-3;
%     if all(indi1<rawN)
%         rawp=raw(indi1,:);
%         %extract the raw data info from data package
%         offset=((1:N_ONBOARD_AUX)-1)*N_BYTES_PER_AUX +3; 
%         auxb(:,m) = sum(rawp(offset+(1:N_BYTES_PER_AUX)') .* pows256b)'; %this line of code will only work in newer versions of matlab, sorry!
%     end
% end
% auxb=3.3*auxb/(2^16-1);
% 
% %% now decode the remote board packages
% 
% %identify remote board packets
% seqk=raw(min(pRemp+2,end));  %contains the sequence data of potential data package; real data packages should be on a consecutive sequence
% dseqk=diff(seqk);
% sbreaks=find(dseqk~=1&dseqk~=-255); %sequence breaks
% 
% try
%     if dseqk(1)==1
%         sbreaks=sbreaks(2:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
%     else
%         %in the unlikely case the first packet was the sequence breaking one
%         sbreaks=sbreaks(1:2:end);  %mark the sequence breaking packages; the second one in the sequence will always be the problem
%     end
% catch
%     disp('')
% end
% 
% accind=pRemp;
% accind(sbreaks)=[];  %remove the sequence breaking packages
% maxrempackpos=0;
% maxrempackpos=max(max(maxrempackpos),max(accind));
% 
% % accelerometer decoding
% if ~isempty(maxrempackpos)
%     try        
%         rem=raw(pRemp-1+(4:2:10))*256+raw(pRemp-1+(5:2:11));
%         if length(pRemp)==1
%             rem=rem';
%         end
%     catch ME
%         disp(ME.meesage)
%     end
%     rem(rem>(2^15-1))=rem(rem>(2^15-1))-2^16;
%     try
%         rem(:,1:3)=rem(:,1:3)/4* 0.488 /1000;
%     catch ME
%         disp(ME.meesage)
%     end
%     try
%     rem(:,4)=rem(:,4)/256+25; %this is actually temperature
%     catch ME
%         disp(ME.meesage)
%     end
%     rem(:,5)=raw(pRemp-1+12);
%     %triggers=raw(pAccp-1+12); %remote trigger byte; 0 means no trigger happened
% else
%     rem=[];
% end
% auxrem(:,1:size(rem,1))=rem';
% 
% %% now decode the status packages
% 
% %assumes all potential status packages ARE status packages (less
% %computationally expensive), and the status packages are not precious data!
% statusdata=nan(length(pStatp));
% 
% for m=1:length(pStatp)
%     indi1=pStatp(m):pStatp(m)+92;
%     if all(indi1<rawN)
%         rawp=raw(indi1);
%         %extract the raw data info from data package
%         statusdata(m) = sum(rawp(2:3) .*  256.^(0:1)');
%     end
% end
% 
% 
% %% select which data channels we are actually interested in based on sd file
% 
% frequs=2*mod(ML(:,1)-1,4)+ML(:,4);  %this assumes fixed frequencies and only 8 different ones, so they repeat after source 4
% 
% for k=1:size(ML,1)
%     data(k,:)=abs(datac(ML(k,2),:,frequs(k)));
% end
% 
% 
% %% now find the remainder bytes, that is, those that were unusued because they likely were part of an incomplete package
% 
% finalbyteused=max([pAux;maxdatapackpos;pStatp;pRemp])+N_BYTES_TO_READ_PER_SAMPLE-1;
% remainderbytes=raw(finalbyteused+1:end); %these bytesshould be appended to beggining of next stream
% 
% 
% %% finally, prepare data output
% 
% avgvout=avgvout(:,~all(isnan(avgvout)));
% maxvout=maxvout(:,~all(isnan(maxvout)));
% 
% dataoutput=[data;auxb;auxrem];
% dataoutput=dataoutput(:,~all(isnan(dataoutput))); %eliminate columns with no data
% 
% packlen=sum(~isnan(dataoutput),2);  %number of samples in data package