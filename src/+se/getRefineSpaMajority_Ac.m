function [mIhw,TW,delays] = getRefineSpaMajority_Ac(preIhw,dFVec,sz,curEvt,TW0,opts,mergedOrNot,delays)
    if(exist('mergedOrNot','var') && mergedOrNot)
        seedIhw = preIhw;
    else
        H = sz(1); W = sz(2); T = sz(3);
        ext = round(opts.minDur/2);
        TWext = max(1,min(TW0)-ext):min(T,max(TW0)+ext);
        refCurve = mean(dFVec(preIhw,TWext),1);
        
        corSigThr = 1e-3;
        n = min(40,numel(TWext));
        zscoreThr = -tinv(corSigThr,n-2);
        tmp = (zscoreThr/sqrt(n-2))^2;
        rThr = sqrt(tmp/(tmp+1));
    
        [ih,iw,it] = ind2sub([H,W,T],curEvt);
        evtIhw = unique(sub2ind([H,W],ih,iw));

        corIhw = [];
        n = numel(TWext);
        maxShift = 1;
        shifts = [max(1,min(TWext)-maxShift):(min(T,max(TWext)+maxShift)-numel(TWext)+1)] - min(TWext);
        for k = 1:numel(shifts)
            TWshift = TWext + shifts(k);
            curves = dFVec(evtIhw,TWshift);
            r = corr(refCurve',curves');
            corIhw = union(corIhw,evtIhw(r>rThr));
        end

        if(isempty(corIhw))
            mIhw = [];
            TW = TW0;
            delays = [];
           return; 
        end

        map = false(H,W);
        map(corIhw) = true;
        pixLst = bwconncomp(map);
        pixLst = pixLst.PixelIdxList;
        areaSz = cellfun(@numel,pixLst);
        [~,id] = max(areaSz);
        seedIhw = pixLst{id};
    end
    
    if(~exist('delays','var'))
        delays = zeros(numel(seedIhw),1);
    end
    [mIhw,TW,delays] = se.seed2Majoirty(seedIhw,dFVec,sz,curEvt,TW0,mergedOrNot,delays);
    
end