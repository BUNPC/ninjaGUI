function errors = SwitchLights(app,command)
%SwitchLights Used to either turn all the lights on or off at the same time
%   command here is either "on" or "off"

message('SwitchLights() is not utilized in NN24. LEDs not toggled on or off.')

return


LightsOn=[254 0 0 0 0 0 255*app.active 255 255 2+app.active]; %command to turn all lights on
LightsOff=[254 0 0 0 0 0 255*app.active 0 0 2+app.active]; %command to turn all lights off

switch command
    case 'on'
        %% generate a state map for all sources on
        ramA=zeros(1024,32);
        % turn them all on sequentially to not have them all at the same
        % time
        nSources=32; %get this value from somewhere else instead
        nLambdas=2;
        powerLevel=[1,0,0]; %I will turn them all on high for better visibility
        %red
        for ki=1:nSources
            ramA(ki,[mod((ki)-1,8)+1,9])=1;
            %ramA(ki,[floor((ki-1)/8)+11,9])=1; %select source board
            ramA(ki,19:21)=powerLevel;
        end
        %IR
        for ki=1+nSources:nLambdas*nSources
            ramA(ki,[mod((ki)-1,8)+1,10])=1;
            %ramA(ki,[floor((ki-1-nSources)/8)+11,10])=1; %select source board
            ramA(ki,19:21)=powerLevel;
        end
        ramA(ki:end,27)=1;

        % create temp stat variable
        stat=initStat(app,stateMap);

        %upload to RAM
        uploadToRAM(app.sp, rama, 'a', false);
        uploadToRAM(app.sp, stat.ramb, 'b', false);

        stat = powerOn( stat);
        stat = ResetCounters(app.sp,stat);

        %start acquisition, to start source sequence
        StartAcquisition(app.sp,stat);
        
    case 'off'
        write(app.sp,LightsOff,"uint8");
end

errors=0;

end