function [sdLst,evtLst,majorityEvt0] = majorCurveFilter(datOrg,dF,sdLst,evtLst,majorityEvt0,opts)
    [H,W,L,T] = size(datOrg);
    isGood = se.curveTestForMajority(datOrg,sdLst,evtLst,majorityEvt0,opts);
    majorityEvt0 = majorityEvt0(isGood);
    sdLst = sdLst(isGood);

    opts.spaSmo = 3;
    for t = 1:T
        dF(:,:,:,t) = -imgaussfilt(dF(:,:,:,t),opts.spaSmo);% spatial smoothing for weakening gap in spatial
    end

    Map = zeros(size(datOrg),'uint16');
    for i = 1:numel(evtLst)
        Map(evtLst{i}) = i;
    end
    dF(Map==0) = -inf;

    [dx,dy,dz,dt] = se.dirGenerate(80);

    % update
    for i = 1:numel(evtLst)
        if isGood(i)
            continue;
        end
        
        pix = evtLst{i};
        evtLst{i} = [];
        Map(pix) = 0;
        [ih,iw,il,it] = ind2sub([H,W,L,T],pix);
        grow = [];
        for k = 1:numel(dx)
            ih0 = min(H,max(1,ih + dx(k)));
            iw0 = min(W,max(1,iw + dy(k)));
            il0 = min(L,max(1,il + dz(k)));
            it0 = min(T,max(1,it + dt(k)));
            grow = [grow;sub2ind([H,W,L,T],ih0,iw0,il0,it0)];
        end
        boundary = setdiff(grow,pix);
        [intensity,id] = max(dF(boundary));
        id = Map(boundary(id));
        if ~isinf(intensity)
            evtLst{id} = [evtLst{id};pix];
            Map(pix) = id;
        end
    end
    evtLst = evtLst(isGood);
end