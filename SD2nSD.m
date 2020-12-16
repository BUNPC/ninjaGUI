function SD2nSD(SDfname,devType)
%SD2NSD Converts .SD probe files to ninjaGUI .nSD probe files
%   SDfname is the file name of the SDfile to convert. devType indicates
%   the hardware type ('ninjaNIRS' or 'NIRS1k'). There is no Matlab output, the
%   function simply creates an nSD file in the folder this function was
%   caled. The nSD file has the same name as the SD file, just with a
%   different extension. 
%% load
load(SDfname,'-mat','SD')

%% Initialize structure
%nSD=SD;
nSD=struct('device',devType,'lambda',500,'nLambdas',2,'nSrcs',0,...
    'nDets',0,'spatialUnit','mm','measList',[0,0,0,0],...
    'srcPos',[0,0,0],'detPos',[0,0,0],'nStates',1,...
    'srcFreqMap',[],'freqMap',[]);

%% Copy the parameters that can simply be copy/pasted

nSD.lambda=SD.Lambda;
nSD.nLambdas=length(SD.Lambda);
nSD.nDummys=SD.nDummys;  %this one is unused by ninjaNIRS but keeping it just in case
nSD.spatiaUnit=SD.SpatialUnit;
nSD.xmin=SD.xmin;
nSD.xmax=SD.xmax;
nSD.ymin=SD.ymin;
nSD.ymax=SD.ymax;
nSD.auxChannels=SD.auxChannels;  %for ninjaNIRS and NIRS1k, the auxiliaries are defined in the hardware configuration file, I might need to do something to reconcile this



%% The following will depend on the type of system
switch devType
    case 'ninjaNIRS'
        %for ninjaNIRS, I need to do a bunch of calculations to assign
        %sources and detectors as, by convention, ninjaNIRS operates with
        %dual optode (source+detector) and thus the number of sources and
        %detector are identical... physically, yet not functionally. This
        %will change in the future though, so we will need to find a way to
        %specify it...
        
        % check the grommet type of the sources; a source with 'none'
        % for now will be considered a short separation source
        SSsrcssIDX=find(contains(SD.SrcGrommetType,'none')); %short separation detector indices
        nOptodes=SD.nSrcs+SD.nDets-length(SSsrcssIDX); 
        nSD.nSrcs=nOptodes;
        nSD.nDets=nOptodes;
        
        %now I need to find the location of the optodes; this will be kind
        %of easy, at least this part, first I will list the detectors and
        %then the sources SANS the SS ones
        indiLSsrc=setdiff(1:SD.nSrcs,SSsrcssIDX); %we need to remove repeats, that is, the SS sources
        optPos=[SD.DetPos;SD.SrcPos(indiLSsrc,:)];
        %the ID number of the sources remains the same, but the detectors
        %get a new index which is simply the original plus the number of
        %sources; the SS detectors get the index of the closest source
        %instead, as they are part of the same optode
        newSrcId=zeros(SD.nSrcs,1);
        %assign the new IDs to LS separation
        newSrcId(indiLSsrc)=SD.nDets+(1:(SD.nSrcs-length(SSsrcssIDX)));
        %now I need to assign IDs to the SS ones, for this I need to find
        %the closest detectors to each one of them
        for ki=1:length(SSsrcssIDX)
            %find minimum distance; assumes no ambiguity
            [~,indiTemp]=min(sqrt(sum((SD.DetPos-SD.SrcPos(SSsrcssIDX(ki),:)).^2,2)));
            newSrcId(SSsrcssIDX(ki))=indiTemp;            
        end   
        
        %now I need to update the measurement list; since I put the
        %detectors
        %at the beggining, their IDs remain the same :). But the sources
        %need to be changed from their original values to the value in
        %newSrcId
        nSD.measList=SD.MeasList;
        nSD.measList(:,1)=newSrcId(SD.MeasList(:,1));
        
        %now, the source and detector positions are simply the optode
        %positions with an offset (as the sources and detectors are
        %separated by 5 mm on the optode). So:
        offset=5;
        nSD.srcPos=optPos;       
        nSD.detPos=optPos;
        nSD.srcPos(:,1)=nSD.srcPos(:,1)-offset/2;
        nSD.detPos(:,1)=nSD.detPos(:,1)+offset/2;        
        
        %I need to assign the frequencies now; it will only actually work
        %if the sources are spread apart; otherwise, users will need to
        %change the frequencies manually. Also, as everything else in this
        %script, assumes just 1 state. It also assumes the system still
        %only has 6 available frequencies. All optodes have to have set
        %frequencies, but the ones configured as detector only should have a
        %frequency of zero (interpreted by ninjaGUI as "source off")
        
        %first set all optodes to zero frequency
        nSD.freqMap=zeros(nOptodes,nSD.nStates,nSD.nLambdas);
        
        %make a list of the source optodes
        srcOptList=sort(unique(nSD.measList(:,1)));
        
        %I will now sort them in order of distance to the source closest to
        %the origin
        [~,sb]=sort(sqrt(sum(nSD.srcPos(srcOptList,:).^2,2)));
        %sb(1) has the index of the source closest to the origin; now we will
        %find the distance of all sources to this one
        dista1=sqrt(sum((nSD.srcPos(srcOptList,:)-nSD.srcPos(srcOptList(sb(1)),:)).^2,2));
        %find the "rank" of closeness to that source
        [~,sb1]=sort(dista1);
        %in sb1, the first element indicates first place in closeness,
        %second the second place etc
        
        %now assign frequencies sequentially by their rank
        for ki=1:length(sb1)
            nSD.freqMap(srcOptList(sb1(ki)),1,1)=mod(ki-1,3)+1;
            nSD.freqMap(srcOptList(sb1(ki)),1,2)=mod(ki-1,3)+4;
        end

        %now make negative the short separation sources; they are easy to
        %identify as their optode IDs are at the beginning of the list
        %before the LS sources (as they share an ID with a detector, and
        %they were put at the beginning)        
        nSD.freqMap(1:SD.nDets,:,:)=-nSD.freqMap(1:SD.nDets,:,:);
       
        
    case 'NIRS1k'
        %for NIRS1k, we can pretty much copy the parameters as they are
        nSD.nSrcs=SD.nSrcs;
        nSD.nDets=SD.nDets;
        nSD.measList=SD.MeasList;
        nSD.srcPos=SD.SrcPos;
        nSD.detPos=SD.DetPos;
end


%% save
fname=SDfname(1:end-3);
save([fname,'.nSD'],'-mat','SD','nSD')
end

