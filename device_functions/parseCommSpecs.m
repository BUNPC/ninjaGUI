function [specs,error]=parseCommSpecs(file)
error=0;
fname=fullfile(file.folder,file.name);
A=readlines(fname);
params2Find={'Type','BaudRate','Parity','DataBits','StopBits',...
    'FlowControl','ByteOrder','TimeOut'};
tipos={'char','double','char','double','double','char','char','double'};
specs=[];
for ki=1:length(params2Find)
    paramIdx=find(contains(A,params2Find{ki}));
    if paramIdx
        linea=A{paramIdx};
        if strcmp(tipos{ki},'char')
            param=linea(length(params2Find{ki})+2:end);
        elseif strcmp(tipos{ki},'double')
            param=str2double(linea(length(params2Find{ki})+2:end));
        end
        specs.(params2Find{ki})=param;
    else
        error=1;
        return
    end
end
end