function compDevices = checkCompatibility()
%checkCompatibility This function determines which hardware devices are
%compatible with the GUI by reading the subfolders of the device_functions
%folder
devFoldName='device_functions';
communicationsFname='communicationSpecs.txt';

addpath(devFoldName)

dire=dir(devFoldName);
%find the valid folders
dispositivos=[dire.isdir];
dispositivos(1:2)=0; %ignore the root folders

compDevFoldNames={dire(dispositivos).name}; 
% these are the devices in the folder, now validate thy are "installed"
% correctly by finding if the specification is correct

%check folder by folder
validFolders=ones(1,length(compDevFoldNames));
for ki=1:length(compDevFoldNames)
    %make sure the required files are in there
    commSpecsFile=dir(fullfile(devFoldName,compDevFoldNames{ki},communicationsFname));
    %if the file was not found, generate an exception    
    if isempty(commSpecsFile)
        validFolders(ki)=0;
        continue
    end
    %read the serial port specifications and save them somewhere
    [portSpecs,parseError]=parseCommSpecs(commSpecsFile);
    if parseError
        validFolders(ki)=0;
        continue
    end
    %check the required functions are present
    functionFiles=dir(fullfile(devFoldName,compDevFoldNames{ki},'*.m'));
    requiredFunctionNameList={'Ask4Status','StateSetup',...
        'ReadBytesAvailable','Acquisition'};
    for kii=1:length(requiredFunctionNameList)
        %if one of the required functions is missing, mark it as
        %incompatible
        indi=contains({functionFiles.name},requiredFunctionNameList{kii});
        if any(indi)
            %now if it contains it, make sure it is identical
            if ~strcmp(functionFiles(indi).name(1:end-2),requiredFunctionNameList{kii})
                validFolders(ki)=0;
                break
            end
        else
            validFolders(ki)=0;
            break
        end
    end

end

%outputs
compDevices = compDevFoldNames(~~validFolders);

%echo the compatible devices
%disp(['Compatibility for ',,'detected'])

end
