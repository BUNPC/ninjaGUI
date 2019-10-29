function  [cfginfo, err] = cw6_loadCFG(cfginfo)



% Ouput 1
if ~exist('cfginfo','var') | isempty(cfginfo)
    cfginfo = initCfginfo();
end

% Ourput 2
err = 0;

err_Parse = 0;
err_Trans = 0;

% Open config file I/O 
fid = fopen('cw6.cfg','r');
if fid<0
    fprintf('Config File ERROR: No cw6.cfg file found\n');
    err = 1;
    return;
end
pathnm = cd();
fprintf('Found cw6.cfg and loading it from %s ...\n\n',pathnm);

% Parse config file into name/value pairs. We don't care about meaning
% of the parameters here, it's all just syntax. 
[params, err_Parse] = parseConfigFile(fid);
if err_Parse~=0
    menu('Config File ERROR: Illegal or corrupted config file','OK');
    err = 2;
end

% Print params
fprintf('Config file parameters are:\n');
fprintf('---------------------------\n');
for ii=1:length(params)
    fprintf('''%s'': {', params(ii).name);
    for jj=1:length(params(ii).val)
        if jj<length(params(ii).val)
            fprintf('''%s'', ', params(ii).val{jj});
        else
            fprintf('''%s''', params(ii).val{jj});
        end
    end
    fprintf('}\n');
end
fprintf('---------------------------\n\n');

% Translate name/value pairs to our cfginfo struct. We care about meaning
% here.
if err_Parse==0
    [cfginfo, err_Trans, foo] = translateParams(params, cfginfo);
end
if err_Trans==1
    menu(sprintf('Config File ERROR: ''%s'' is an unknown parameter', foo),'OK');
    err = 3;
end
if err_Trans==2
    menu(sprintf('Config File ERROR: Parameter ''%s'' has no assigned value', foo),'OK');
    err = 3;
end


% Close config file I/O
fclose(fid);




% ---------------------------------------------------------
function cfginfo = initCfginfo()

cfginfo = struct(...
        'commPort','', ...
        'auxList',{{'Nothing'}}, ...
        'editBoxes', struct('autogain',100, 'sampleRate',500), ...
        'DataCollectionMode','60min', ...
        'email_address','', ...
        'email_passwd','', ...
        'email_recipient','', ...
        'email_subject','', ...
        'LaserPowerControl',0, ...
        'displayHemoglobin',0, ...
        'threshSignalMin',60, ...
        'threshSignalMax',120, ...
        'threshDetMax',130, ...
        'threshNoise',0.05, ...
        'Src', struct('initialPwr',50, 'AutoGain',100), ...
        'Det', struct('initialGain',1, 'AutoGain',120), ...
        'SrcDet', struct('displayFlag','0', 'AutoGain',120) ...
);



% ---------------------------------------------------------
function [params, err] = parseConfigFile(fid)

% Legal syntax:
%
% 
% % END
%
% % name1
% % END
%
% % name1
% val11
% % END
%
% % name1
% val11
% val12
% ....
% val1m
% % END
%
%


params = struct('name','','val',{});
err = 0;

iP=1;
linestr = '';
while ~eof(linestr)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Find next parameter's name %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    while ~isParamName(linestr)        
        linestr = fgetl(fid);
        if eof(linestr)
            err=1;
            return;
        end
        if endOfConfig(linestr)
            return;
        end
        if isParamVal(linestr)
            err=2;
            return;
        end
    end   
    name = getParamNameFromLine(linestr);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Find next parameter's value %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ii=1;    
    linestr = '';
    val = {};
    while 1
        fp_previous = ftell(fid);
        linestr = fgetl(fid);        
        if isempty(linestr)
            continue;
        end
        if eof(linestr)
            err=1;
            return;
        end
        if endOfConfig(linestr)
            fseek(fid, fp_previous, 'bof');
            break;
        end
        if isParamName(linestr)
            fseek(fid, fp_previous, 'bof');
            break;
        end
        val{ii} = getParamValueFromLine(linestr);
        ii=ii+1;
    end    
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Assign name/value pair to next param %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    params(iP).name = name; 
    params(iP).val = val;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Move on to the next Param %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    linestr='';
    iP=iP+1;
    
end



% ---------------------------------------------------------
function  [cfginfo, err, badparam] = translateParams(params, cfginfo)

err=0;
badparam = [];

for ii=1:length(params)
    
    if isempty(params(ii).val)
        badparam = params(ii).name;
        err = 2;
        return;
    end
    
    switch lower(params(ii).name)
        case 'comm port'
            cfginfo.commPort = params(ii).val{1};
            
        case 'aux list'
            cfginfo.auxList = params(ii).val;
            
        case 'auto gain'
            cfginfo.editBoxes.autogain = str2num(params(ii).val{1});
            
        case 'sample rate'
            cfginfo.editBoxes.sampleRate = str2num(params(ii).val{1});
            
        case 'data collection mode'
            cfginfo.DataCollectionMode = params(ii).val{1};
            
        case 'email address'
            cfginfo.email_address = params(ii).val{1};
            
        case 'email password'
            cfginfo.email_passwd = params(ii).val{1};
            
        case 'email recipient'
            cfginfo.email_recipient = params(ii).val{1};
            
        case 'email subject'
            cfginfo.email_subject = params(ii).val{1};
            
        case 'laser power control'
            if strcmpi(params(ii).val{1},'on')
                cfginfo.LaserPowerControl = 1;
            else
                cfginfo.LaserPowerControl = 0;
            end
            
        case 'display hemoglobin'
            cfginfo.displayHemoglobin = str2num(params(ii).val{1});
            
        case 'thresh signal min'
            cfginfo.threshSignalMin = 60;
            
        case 'thresh signal max'
            cfginfo.threshSignalMax = 120;
            
        case 'thresh det max'
            cfginfo.threshDetMax = 130;
            
        case 'thresh noise'
            cfginfo.threshNoise = 0.05;
            
        case 'initial source power'
            cfginfo.Src.initialPwr = str2num(params(ii).val{1});
            
        case 'source power autogain'
            cfginfo.Src.AutoGain = str2num(params(ii).val{1});
            
        case 'initial detector power'
            cfginfo.Det.initialGain = str2num(params(ii).val{1});
            
        case 'detector autogain'
            cfginfo.Det.AutoGain = str2num(params(ii).val{1});
            
        case 'autogain source and detector flag'
            cfginfo.SrcDet.displayFlag = str2num(params(ii).val{1});
            
        case 'autogain source and detector'
            cfginfo.SrcDet.AutoGain = str2num(params(ii).val{1});
            
        otherwise
            badparam = params(ii).name;
            err = 1;
    end
    
end



% ---------------------------------------------------------
function b = isParamName(linestr)

b = false;

if isempty(linestr)
    return;
            end
for ii=1:length(linestr)
    if linestr(ii)~=' ';
        break;
    end
end
if linestr(ii)=='%'
    b=true;
end



% ---------------------------------------------------------
function b = isParamVal(linestr)

b = false;

if isempty(linestr)
    return;
    end
if isalnum(linestr(1))
    b=true;
end



% ---------------------------------------------------------
function b = endOfConfig(linestr)

b = false;

if isempty(linestr)
    return;
end
k = find(linestr==' ');
linestr(k)=[];
if strcmp(lower(linestr),'%end')
    b=true;
end



% ---------------------------------------------------------
function b = eof(linestr)

b = false;

if linestr==-1
    b=true;
end



% ---------------------------------------------------------
function name = getParamNameFromLine(linestr)

name = '';
if isempty(linestr)
    return;
end

ii=1;
while ii<length(linestr) & linestr(ii)~='%'
    ii=ii+1;
end
while ii<length(linestr) & ~isalnum(linestr(ii))
    ii=ii+1;
end
jj=ii;
while jj<length(linestr) & (linestr(jj)~='\n' | linestr(jj)~='\r')
    jj=jj+1;
end
name = linestr(ii:jj);





% ---------------------------------------------------------
function val = getParamValueFromLine(linestr)

val = '';
if isempty(linestr)
    return;
end

ii=1;
while ii<length(linestr) & linestr(ii)==' '
    ii=ii+1;
end
jj=ii;
while jj<length(linestr) & (linestr(jj)~='\n' | linestr(jj)~='\r')
    jj=jj+1;
end
val = linestr(ii:jj);




% ---------------------------------------------------------
function y = isalnum( x )

y = all( (x>='0' & x<='9') | (x>='a' & x<='z') | (x>='A' & x<='Z') );


