function cw6_init( handles )

cw6info.cfg=handles.devinfo.cfg;


if cw6info.cfg.displayHemoglobin==0
    set(handles.checkboxDisplayHbX,'visible','off');
end

if cw6info.cfg.SrcDet.displayFlag==0
    set(handles.pushbuttonAutoGainSrcDet,'visible','off');
    set(handles.editAutoGainSrcDet,'visible','off');
    set(handles.textAutoGainSrcDet,'visible','off');    
end

if cw6info.cfg.LaserPowerControl==0
    set(handles.textSetSrcPower,'visible','off');
    set(handles.pushbuttonSetSrcPower,'visible','off');
    set(handles.editSetSrcPower,'visible','off');
    set(handles.textSetSrcPowerAll,'visible','off');
    set(handles.editSetSrcPowerAll,'visible','off');
    set(handles.textAutoGainSrcDet,'visible','off');
    set(handles.pushbuttonAutoGainSrcDet,'visible','off');
    set(handles.editAutoGainSrcDet,'visible','off');
    set(handles.menuLaserLinearityCalibration,'visible','off');
    for ii=1:32
        eval( sprintf('set(handles.editSrcPower%d,''visible'',''off'');',ii) )
    end
end


% load the tooltip information

set(handles.textDetSumMax,'Tooltip',sprintf('If signals summed on detector from all channels exceeds this value,\nthen a red box is placed around the detector number.') )
set(handles.textSignalMax,'Tooltip',sprintf('If the channel signal exceeds this value,\nthen the channel line connecting source and detector is red.') )
set(handles.textSignalMin,'Tooltip',sprintf('If the channel signal is less than this value,\nthen the channel line connecting the source and detector is blue.') )
set(handles.textNoiseThresh,'Tooltip',sprintf('If the channel noise exceeds this value in OD units,\nthen the channel line connecting the source and detector is yellow.') )

set(handles.editDetSumMax,'Tooltip',sprintf('If signals summed on detector from all channels exceeds this value,\nthen a red box is placed around the detector number.') )
set(handles.editSignalMax,'Tooltip',sprintf('If the channel signal exceeds this value,\nthen the channel line connecting source and detector is red.') )
set(handles.editSignalMin,'Tooltip',sprintf('If the channel signal is less than this value,\nthen the channel line connecting the source and detector is blue.') )
set(handles.editStdThresh,'Tooltip',sprintf('If the channel noise exceeds this value in OD units,\nthen the channel line connecting the source and detector is yellow.') )



set(handles.textDisplayWindow,'Tooltip',sprintf('Number of seconds to display in the scrolling plot.') )
set(handles.checkboxDisplayHbX,'Tooltip',sprintf('Check this to display hemoglobin concentration changes\nin units of Molar mm.') )
set(handles.checkboxDisplayNormalized,'Tooltip',sprintf('Check this to display OD changes.') )
set(handles.checkboxAutoscale,'Tooltip',sprintf('Check this to autoscale the display.') )
set(handles.textYrange,'Tooltip',sprintf('Set the Yrange for the display. This retains the entered range\nfor absolute, OD, and hemoglobin scales.') )

set(handles.editDisplayWindow,'Tooltip',sprintf('Number of seconds to display in the scrolling plot.') )
set(handles.editYrange,'Tooltip',sprintf('Set the Yrange for the display. This retains the entered range\nfor absolute, OD, and hemoglobin scales.') )


set(handles.editSetSrcPower,'Tooltip',sprintf('Push to auto set laser powers to achieve a max channel signal level\ngiven by this value.') )
set(handles.pushbuttonSetSrcPower,'Tooltip',sprintf('Push to auto set laser powers to achieve a max channel signal level\ngiven by this value.') )
set(handles.textSetSrcPower,'Tooltip',sprintf('Push to auto set laser powers to achieve a max channel signal level\ngiven by this value.') )

set(handles.textSetSrcPowerAll,'Tooltip',sprintf('Edit to set all laser powers to this level.\nThe level ranges from 1 to 100 percent.') )
set(handles.editSetSrcPowerAll,'Tooltip',sprintf('Edit to set all laser powers to this level.\nThe level ranges from 1 to 100 percent.') )

set(handles.textSetGain,'Tooltip',sprintf('Push to auto set detector gains to achieve a max channel signal level\ngiven by this value.') )
set(handles.pushbuttonSetGain,'Tooltip',sprintf('Push to auto set detector gains to achieve a max channel signal level\ngiven by this value.') )
set(handles.editAutoGainLevel,'Tooltip',sprintf('Push to auto set detector gains to achieve a max channel signal level\ngiven by this value.') )

set(handles.textGainAll,'Tooltip',sprintf('Edit to set all detector gains to this value.\nThe value can range from 1 to 255, but larger than 100 will likely not benefit the SNR.') )
set(handles.editGainAll,'Tooltip',sprintf('Edit to set all detector gains to this value.\nThe value can range from 1 to 255, but larger than 100 will likely not benefit the SNR.') )

set(handles.textAutoGainSrcDet,'Tooltip',sprintf('Push to optimize laser powers and detector gains\nsimultaneously. Why theoretically this is better than doing the\nlaser power and detector gain individually.\nIn pratice, users prefer doing them individually over using this option.') )
set(handles.editAutoGainSrcDet,'Tooltip',sprintf('Push to optimize laser powers and detector gains\nsimultaneously. Why theoretically this is better than doing the\nlaser power and detector gain individually.\nIn pratice, users prefer doing them individually over using this option.') )
set(handles.pushbuttonAutoGainSrcDet,'Tooltip',sprintf('Push to optimize laser powers and detector gains\nsimultaneously. Why theoretically this is better than doing the\nlaser power and detector gain individually.\nIn pratice, users prefer doing them individually over using this option.') )

set(handles.editRate,'Tooltip',sprintf('Edit to change the data acquisition sample rate.\nData acquisition always has a 25 Hz bandwidth. A sample rate of 50 or larger\nis needed to satisfy Nyquist, but larger sample rates can cause\ndata transfer issues.') )
set(handles.textRate,'Tooltip',sprintf('Edit to change the data acquisition sample rate.\nData acquisition always has a 25 Hz bandwidth. A sample rate of 50 or larger\nis needed to satisfy Nyquist, but larger sample rates can cause\ndata transfer issues.') )

foos = sprintf('Push to check if detectors are saturated.\nThis procedure takes ~5 sec to reduce the laser power by half and\nreturn it to normal levels. If it finds that the channel signals do not decrease as expected,\nthe corresponding detector is given a red background to indicate that it is\nsaturated and that the user needs to make adjustments. The red background\nremains until the issue is fixed and this button is pressed again.');
set(handles.pushbuttonCheckSaturation,'Tooltip', foos )

%set(handles.,'Tooltip',sprintf('\n') )

