function errors = TurnSourceN(app,N,L)
%TurnSourceN Function to turn on or off source N to a determined level L
%   The GUI sends L as an 1-by-NL array, where NL is the number of
%   wavelengths on each source

errors=0;

CMD_LED_STATE = bin2dec('11000010');

%SourceNOn=[2 N-1 CMD_LED_STATE round(15/2*(sign(L)).^2+9/2*(sign(L)))];  %Turns on source N at level L: L=0 off, L=1 high, L=-1 low
%SourceNOff=[2 N-1 CMD_LED_STATE L];  %Turns off source N
SourceNIndL=[2 N-1 CMD_LED_STATE round(5*(sign(L(1))).^2+3*(sign(L(1))))+round(5/2*(sign(L(2))).^2+3/2*(sign(L(2))))];  %Changes state of each LED on source N individually; L should be a 1x2 vector specifying each level

write(app.sp,SourceNIndL,'uint8')


end