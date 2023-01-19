function result = StateSetup(app,statefMap)
%StateSetupS The purpose of this function is to setup the state of the
%sources, detectors for the acquisition. Can be used to setup the
%frequencies of the LEDs, or the power levels if they are fixed, or the
%state sequences if there is temporal multiplexion

sp=app.sp;

result=0;

CMD_LED_STATE = bin2dec('11000010');
CMD_SEL_F1 = bin2dec('11000011');
CMD_SEL_F2 = bin2dec('11000100');

fMap=abs(statefMap);

try
    if prod(size(fMap))==2   %case of only one optode        
        write(sp,[4 0 CMD_SEL_F1 fMap(1) CMD_SEL_F2 fMap(2)],'uint8')
    else
        for k=1:length(statefMap)
            write(sp,[4 k-1 CMD_SEL_F1 fMap(k,1) CMD_SEL_F2 fMap(k,2)],'uint8');
        end
    end
catch
    
    disp('Frequencies could not be set')
    
end

result=1;
end

