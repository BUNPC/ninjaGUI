function mappedIndices=mapToMeasurementList(stateMap,measList)
%% Function to map the state map (detector and sources) to standard measurement list
% the standard measurement list is a list of four element arrays, each one
% indicates, the source, the detector and the wavelength associated which
% each channel. The function will identiy which which channel corresponds
% to which state and will return the indices that move the elements of the
% B matrix to their correct channel position

%% identify which state is associated with which source

foo=find(stateMap(:,27)==1);
N_STATES=foo(1);

sourceID=stateMap(1:N_STATES,1:8);
wavelengthID=stateMap(1:N_STATES,9:10); 
sourceBoardId=stateMap(1:N_STATES,11:16); 

%% CROP THE ID LISTS TO THE VALID NUMBER OF STATES

%% LOOP STATE BY STATE