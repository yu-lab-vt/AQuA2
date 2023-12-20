function [datWarp] = warpRef2Tst(path,ref,sz)
%WARPREF2TST warp the reference curve to each super pixel

T = sz(4);
nSp = numel(path);
datWarp = zeros(nSp,T,'single');
for kk=1:nSp
    x0 = nan(1,T);  % warped curve
    c0 = zeros(1,T);  % count the occurrence
    p0 = path{kk}(:,1:2);
    idxValid = p0(:,1)>=1 & p0(:,1)<=T & p0(:,2)>=1 & p0(:,2)<=T;
    p0 = p0(idxValid,:);
    for tt=1:length(p0)
        p_ref = p0(tt,1);
        p_tst = p0(tt,2);
        if ~isnan(ref(p_ref))
            if isnan(x0(p_tst))
                x0(p_tst) = ref(p_ref);
            else
                x0(p_tst) = x0(p_tst) + ref(p_ref);
            end
            c0(p_tst) = c0(p_tst) + 1;
        end
    end
    c0(c0==0) = 1;
    datWarp(kk,:) = x0./c0;
end

end

