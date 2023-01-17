function mappedIndices=mapToMeasurementList(stateMap,measList)
%% Function to map the state map (detector and sources) to standard measurement list
% the standard measurement list is a list of four element arrays, each one
% indicates, the source, the detector and the wavelength associated which
% each channel. The function will identiy which which channel corresponds
% to which state and will return the indices that move the elements of the
% B matrix to their correct channel position
% RIGHT NOW MAPPED INDICES IS NOT WHAT IT IS SUPPOSED TO BE, I AM NOT SURE
% HOW TO DO THE INDEXING AND THE ARRAYS BEING 3D COMPLICATES THINGS

%% identify which state is associated with which source

foo=find(stateMap(:,27)==1);
N_STATES=foo(1);

%cropped ID lists to the valid states
sourceIDs=stateMap(1:N_STATES,1:8);
wavelengthIDs=stateMap(1:N_STATES,9:10); 
sourceBoardIds=stateMap(1:N_STATES,11:16); 

%% LOOP MEASUREMENT BY MEASUREMENT TO FIND IN STATES
estados=nan(1,length(measList));
for ki=1:size(measList,1)
    meas=measList(ki,:);
    srcID=meas(1);
    detID=meas(2);
    lambdaID=meas(4);
    %there will be the assumption that wavelengths are sorted from short to
    %long in the measurement list AND in the indicator bits of the data
    %packet/stateMap
    %detBoardID=ceil(srcID/8); %assumes sources 1:8 are on board 1, 9:16 on
    %board 2, etc; however, this has not been implemented in the firmware
    %yet apparently, so needs to be implemented later
    %when multiple sourceboards are implemented, the code below needs to be
    %expanded to use sourceboardIDs too in the calculations. For example
    %wavelengthIDs(:,lambdaID)&sourceIDs(:,srcID)&sourceboardIDs(:,detBoardId);
    %Identify state for the current source and wavelength; assumption that
    %only one states uses it
    try
        %if some sources are never turned on but are required by the
        %measurement list, those states will be marked as nan
        estados(ki)=find(wavelengthIDs(:,lambdaID)&sourceIDs(:,srcID));
    end
end
% estados now contains a list of which measurement list corresponds with
% what state. Combined with the detector list on the measurement list, this
% can be converted to a map
mappedIndices=[estados',measList(:,2)];

