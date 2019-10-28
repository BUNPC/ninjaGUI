function result = ninja_MapFrequencies(sp,statefMap)
%NINJA_MAPFREQUENCIES Sets the LED frequencies for ninjaNIRS
%   sp is the serial port object the ninjaNIRS is connected to (so we can
%   relay the LED frequencies to that port). statefMap is the frequency map
%   for the desired frequency state (if there is no time multiplexing, then
%   there is only one state). statefMap needs to be an array with size
%   [nSrcs,nWavelengths], so element i,j would specify the frequency for
%   LED j on source i. Negative frequencies just mean low intensity/short
%   separation channels for ninjaNIRS, but as this script only sets the
%   frequency, the sign will be ignored.

result=0;

CMD_LED_STATE = bin2dec('11000010');
CMD_SEL_F1 = bin2dec('11000011');
CMD_SEL_F2 = bin2dec('11000100');

fMap=abs(statefMap);

try
    for k=1:length(statefMap)
        fwrite(sp,[4 k-1 CMD_SEL_F1 fMap(k,1) CMD_SEL_F2 fMap(k,2)]);
    end
catch
    disp('Frequencies could not be set')    
end

result=1;
end

