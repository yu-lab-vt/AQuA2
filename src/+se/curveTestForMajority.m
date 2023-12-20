function isGood = curveTestForMajority(datOrg,sdLst,evtLst,majorityEvt0,opts)
    [H,W,L,T] = size(datOrg);
    datVec = reshape(datOrg,[],T);
    
    isGood = true(numel(evtLst),1);
    for i = 1:numel(evtLst)
        [ih,iw,il,it] = ind2sub([H,W,L,T],sdLst{i});
        t00 = min(it);
        t11 = max(it); 

        [ih,iw,il,it] = ind2sub([H,W,L,T],evtLst{i});
        select = it>=t00 & it<=t11;
        ihw = unique(sub2ind([H,W,L],ih(select),iw(select),il(select)));
        t0 = min(it); t1 = max(it);
        evtCurve = mean(datVec(ihw,:),1);

        t_scl = max(1,round((t1-t0+1)/opts.TPatch));
        curve0 = se.myResize(evtCurve,1/t_scl);
        hasPeak =  se.eventCurveSignificance(curve0,max(1,floor(t0/t_scl)),ceil(t1/t_scl),max(1,floor(t00/t_scl)),ceil(t11/t_scl),opts.sigThr);
        if ~hasPeak
            disp(i)
            isGood(i) = false;
    %         figure;plot(evtCurve);hold on;plot(t0:t1,evtCurve(t0:t1));plot(t00:t11,evtCurve(t00:t11));
        end
    end
end