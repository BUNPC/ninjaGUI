function errors = SwitchLights(app,command)
%SwitchLights Used to either turn all the lights on or off at the same time
%   command here is either "on" or "off"

LightsOn=[254 0 0 0 0 0 255*app.active 255 255 2+app.active]; %command to turn all lights on
LightsOff=[254 0 0 0 0 0 255*app.active 0 0 2+app.active]; %command to turn all lights off

switch command
    case 'on'
        %% generate a state map for all sources on
        ramA=zeros(1024,32);
        % turn them all on sequentially

        write(app.sp,LightsOn,"uint8");
    case 'off'
        write(app.sp,LightsOff,"uint8");
end

errors=0;

end