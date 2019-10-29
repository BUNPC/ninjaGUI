function [f,t,tIdx,boffset] = cw6_correctShiftError(a, nWords, tIdx, boffset)

%nWords = size(hexdat,1);
dIdx=0;
fIdx = 0;
nRec = 0;
a2=a(:);
f=[];
t=[];
while dIdx<=nWords-257
    drng = dIdx+[1:257];
    nRec = nRec + 1;
    if a2(drng(end)*4-3-boffset)~=196 | a2(drng(end)*4-2-boffset)~=121
        lst = find(a2(drng(end)*4-3-boffset-[1:16])==196 & a2(drng(end)*4-2-boffset-[1:16])==121 & a2(drng(end)*4-1-boffset-[1:16])==192);
        if ~isempty(lst)
            boffset = boffset + lst(1);
        end
%        f(drng) = 0;
    else
        frng = fIdx*257+[1:257];
%        a = fliplr(reshape(a2(dIdx*4-boffset+[1:257*4]), [4 257])');
        a = reshape(a2(dIdx*4-boffset+[1:257*4]), [4 257])';
        foo=reshape(dec2bin(a',8)',[32 257])';
        lst=find(foo(:,10:end)=='1');
        radix=1e10*ones(size(foo,1),23);
        radix(lst)=1;
        radix = -radix*diag([1:23]);
        f(frng)=(-1).^str2num(foo(:,1)) .* 2.^(bin2dec(foo(:,2:9))-127) .* (1+sum(2.^radix,2));
        fIdx = fIdx + 1;
        t(fIdx) = tIdx;
%         if mod(nRec,2)==0
%             figure(3)
%             plot(f)
%             ylim([-1 1]*1000)
%         end
    end
    dIdx = dIdx + 257;
    tIdx = tIdx + 1;
end


