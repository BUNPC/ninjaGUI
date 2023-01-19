function errors = TurnSourceN(app,N,L)
%TurnSourceN Function to turn on or off source N to a determined level L
%   The GUI sends L as an 1-by-NL array, where NL is the number of
%   wavelengths on each source

errors=0;
SourceNIndL=[254 0 0 0 0 255-255 255-255 bin2dec(num2str(flipud(app.LEDstate)'))' app.active]; %command for this device

%for this type of device, N and L are not used since sources cannot be
%controlled individually: all sources need to be set at the same time
%for this reason, the function uses the GUI variable that stores the
%desired level of each source instead

write(app.sp,SourceNIndL,'uint8')


end