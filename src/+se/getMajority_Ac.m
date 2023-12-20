function majorityEvt0 = getMajority_Ac(sdLst,evtLst,dF,opts)
    [H,W,L,T] = size(dF);
    majorityEvt0 = cell(numel(sdLst),1);
    dF = reshape(dF,[],T);
    for i = 1:numel(sdLst)
        % initialization
        [ih,iw,il,it] = ind2sub([H,W,L,T],sdLst{i});
        t0 = min(it);
        t1 = max(it);
        ihw = unique(sub2ind([H,W,L],ih,iw,il));
        % seed to majority
        [mIhw,TW,delays] = se.seed2Majoirty(ihw,dF,[H,W,L,T],evtLst{i},t0,t1,opts);
        % update
        majorityEvt0{i}.ihw = mIhw;
        majorityEvt0{i}.TW = TW;
        majorityEvt0{i}.delays = delays;
        if length(TW)~=1
            ihw = union(ihw,mIhw(delays==0));
            curve00 = mean(dF(ihw,TW),1);   % use seed curve as reference
            curve00 = curve00 - min(curve00);
            curve00 = curve00/max(curve00);
        else
            curve00 = 1;
        end
        majorityEvt0{i}.curve = curve00;
        
    end
end