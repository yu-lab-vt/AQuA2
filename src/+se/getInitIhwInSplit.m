function [seedIhw] = getInitIhwInSplit(refCurve,dF,sz,pix,t00,t11,opts)
    H = sz(1); W = sz(2); L = sz(3); T = sz(4);
    [ih,iw,il,it] = ind2sub([H,W,L,T],pix);
    t0 = min(it);
    t1 = max(it);
    ihw = unique(sub2ind([H,W,L],ih,iw,il));
    [TW,tPeak] = se.getMajorityTem(refCurve,t00,t11,t0,t1);

    t_scl = max(1,round(numel(TW)/opts.TPatch));
    refCurve = se.myResize(refCurve(TW),1/t_scl);
%     refCurve = refCurve(t00:t11);

    curves = dF(ihw,TW);
    curves = se.myResize(curves,'Scale',[1,1/t_scl]);
    rThr = 0.6; % set 70% correlation as threshold
    

    % whether correlated
    r = corr(refCurve',curves')';
    select = r>rThr;
    selectPix = ihw(select);     r = r(select);

    % check whether the peaks of those pixels belong to current event
    newAddVox = selectPix + H*W*(tPeak + 1);
    select1 = ismember(newAddVox,pix);
    selectPix = selectPix(select1); r = r(select1);

    if isempty(selectPix)
        seedIhw = [];
        return
    end
    
    % check connectivity
    map = false(H,W,L);
    map(selectPix) = true;
    pixLst = bwconncomp(map);
    pixLst = pixLst.PixelIdxList;
    areaSz = cellfun(@numel,pixLst);
    [~,id] = max(areaSz);
    seedIhw = pixLst{id};
end