function errors = TurnSourceN(app,N,L)
%TurnSourceN Function to turn on or off source N to a determined level L
%   The GUI sends L as an 1-by-NL array, where NL is the number of
%   wavelengths on each source

errors=0;
disp(['Fake turned on source ',num2str(N), 'to level ', num2str(L)])


end