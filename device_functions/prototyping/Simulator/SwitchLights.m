function errors = SwitchLights(app,command)
%SwitchLights Used to either turn all the lights on or off at the same time
%   command here is either "on" or "off"

switch command
    case 'on'
        disp('Fake turned the lights on')
    case 'off'
        disp('Fake turned the lights off')
end

errors=0;

end