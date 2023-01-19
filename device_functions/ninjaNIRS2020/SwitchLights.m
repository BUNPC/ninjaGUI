function errors = SwitchLights(app,command)
%SwitchLights Used to either turn all the lights on or off at the same time
%   command here is either "on" or "off"

CMD_LED_STATE = bin2dec('11000010');
LightsOff=[2 255 CMD_LED_STATE 0]; %command to turn all lights off
LightsOn=[2 255 CMD_LED_STATE 12]; %command to turn all lights on

switch command
    case 'on'
        write(app.sp,LightsOn,"uint8");
    case 'off'
        write(app.sp,LightsOff,"uint8");
end

errors=0;

end