function [n,v] = cw6_firmwareVer(s)

n = [];

k = strfind(s,',v');
v = s(k+2:end);

k = find(v == '.');
if isempty(k)
    n = str2num(v);
    return;
end
n = str2num(v);


%{
x(length(k)+1) = str2num(v(1:k(1)-1));
for ii=1:length(k)
    if ii+1<=length(k)
        x(length(k)+1 - ii) = str2num(v(k(ii)+1:k(ii+1)-1));
    end
end
x(1) = str2num(v(k(ii)+1:end));

n = 0;
for ii=1:length(x)
    n = n + x(ii) * 10^(ii-1);
end
%}