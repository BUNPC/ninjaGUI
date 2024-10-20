function mappedIndices=mapToMeasurementList(srcram,measList,srcPowerLowHigh)
%% Function to map the state map (detector and sources) to standard measurement list
% the standard measurement list is a list of four element arrays, each one
% indicates, the source, the detector and the wavelength associated which
% each channel. The function will identiy which which channel corresponds
% to which state and will return the indices that move the elements of the
% B matrix to their correct channel position
% RIGHT NOW MAPPED INDICES IS NOT WHAT IT IS SUPPOSED TO BE, I AM NOT SURE
% HOW TO DO THE INDEXING AND THE ARRAYS BEING 3D COMPLICATES THINGS


if ~exist('srcPowerLowHigh')
    srcPowerLowHigh = [];
end

SSfirstDidx = max(measList(:,2))+1;
if size(measList,2)==5
    rhoSDS = measList(:,5);
    lstDindices = measList(find(rhoSDS<10),2); % these are the SS detectors
    SSfirstDidx = min(lstDindices); % this is the first SS detector. The next 7 are also assumed to be SS detectors measured by this first same Det Inde
end


%% identify which state is associated with which source

foo=find(srcram(1,:,32)==1);
N_STATES=foo(1);


%% LOOP MEASUREMENT BY MEASUREMENT TO FIND IN STATES
estados=nan(1,size(measList,1));
estados2=nan(1,size(measList,1));
estados_det=nan(1,size(measList,1));
for ki=1:size(measList,1)
    meas=measList(ki,:);
    
    srcID0 = meas(1);
    srcID = srcID0; %mod(srcID0-1,8)+1;
    srcModule = ceil((srcID0-0.1)/8);

    sourceIDs = squeeze( srcram( srcModule, 1:N_STATES, [17:20 31]) ); % bit 31 is a hack from createLEDPowerCalibrationSrcRAM to help us identify src 0

                                                                 
    detID=meas(2);
    lambdaID=meas(4);

    detID0 = detID;
    if detID >= SSfirstDidx % this is SS detector
        detID = SSfirstDidx;
    end

    try
        %if some sources are never turned on but are required by the
        %measurement list, those states will be marked as nan
        foo = mod(srcID-1,8)*2 + (lambdaID-1);
        Lia = ismember(sourceIDs,bitget( foo, 1:5 ),'rows');
        lst = find(Lia==1);
        if length(lst)==1
            estados(ki) = lst;
        else
            estados(ki) = lst( srcPowerLowHigh(srcID,detID0,lambdaID) );
        end
        iDark = find( srcram(srcModule,(estados(ki)+1):N_STATES, 21)==1, 1 ) + estados(ki);
        estados2(ki) = iDark;

        estados_det(ki) = detID;
    end
end
% estados now contains a list of which measurement list corresponds with
% what state. Combined with the detector list on the measurement list, this
% can be converted to a map
mappedIndices=[estados',estados_det',estados2'];

