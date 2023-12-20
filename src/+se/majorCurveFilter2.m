function [sdLst,evtLst,majorityEvt0] = majorCurveFilter2(datOrg,dF,sdLst,evtLst,majorityEvt0,opts)
    [H,W,L,T] = size(datOrg);
    opts.spaSmo = 3;
    scoreMap = zeros(size(dF));
    for t = 1:T
        scoreMap(:,:,:,t) = -imgaussfilt(dF(:,:,:,t),opts.spaSmo);% spatial smoothing for weakening gap in spatial
    end

    Map = zeros(size(datOrg),'uint16');
    for i = 1:numel(evtLst)
        Map(evtLst{i}) = i;
    end
    scoreMap(Map==0) = -inf;
    datVec = reshape(datOrg,[],T);
    [dx,dy,dz,dt] = se.dirGenerate(80);
    majorUpdate = [];
    if L==1
        SE = strel(true(8,8,8));
    else
        SE = strel(true(8,8,8,8));
    end

    % update
    for i = 1:numel(evtLst)
        [ih,iw,il,it] = ind2sub([H,W,L,T],sdLst{i});
        t00 = min(it);
        t11 = max(it); 

        %% check curve
        pix = evtLst{i};
        [ih,iw,il,it] = ind2sub([H,W,L,T],pix);
        select = it>=t00 & it<=t11;
        ihw = unique(sub2ind([H,W,L],ih(select),iw(select),il(select)));
        t0 = min(it); t1 = max(it);
        evtCurve = mean(datVec(ihw,:),1);

        t_scl = max(1,round((t1-t0+1)/opts.TPatch));
        curve0 = se.myResize(evtCurve,1/t_scl);
        hasPeak =  se.eventCurveSignificance(curve0,max(1,floor(t0/t_scl)),ceil(t1/t_scl),max(1,floor(t00/t_scl)),ceil(t11/t_scl),opts.sigThr);
        if hasPeak
            continue;
        end
        
%         disp(i)
%         figure;plot(evtCurve);hold on;plot(t0:t1,evtCurve(t0:t1));plot(t00:t11,evtCurve(t00:t11));
%         map000=false(H,W,T);map000(evtLst{i}) = true;zzshow(map000(:,:,t0:t1))

        evtLst{i} = [];

        %% watershed
        ext = 1;
        rgh = max(1,min(ih)-ext):min(H,max(ih)+ext); H0 = numel(rgh); ih = ih - min(rgh) + 1;
        rgw = max(1,min(iw)-ext):min(W,max(iw)+ext); W0 = numel(rgw); iw = iw - min(rgw) + 1;
        rgl = max(1,min(il)-ext):min(L,max(il)+ext); L0 = numel(rgl); il = il - min(rgl) + 1;
        rgt = max(1,min(it)-ext):min(T,max(it)+ext); T0 = numel(rgt); it = it - min(rgt) + 1;
        pix0 = sub2ind([H0,W0,L0,T0],ih,iw,il,it);
        % Map seed regions

        Map0 = Map(rgh,rgw,rgl,rgt);
        % find neighbor labels
        newAdd = [];
        for ii=1:numel(dx)
            ih1 = min(max(ih + dx(ii),1),H0);
            iw1 = min(max(iw + dy(ii),1),W0);
            il1 = min(max(il + dz(ii),1),L0);
            it1 = min(max(it + dt(ii),1),T0);
            vox1 = sub2ind([H0,W0,L0,T0],ih1,iw1,il1,it1);
            newAdd = [newAdd;vox1];
        end
        neib0 = setdiff(Map0(newAdd),[0,i]);
        if numel(neib0)==0
            Map(pix) = 0;
            continue;
        elseif numel(neib0)==1
            curLabel = neib0(1);
            Map(pix) = curLabel;
            evtLst{curLabel} = [evtLst{curLabel};pix];
            majorUpdate = union(majorUpdate,curLabel);
            continue;

        end
        
        possibleSeeds = setdiff(Map0(:),[0,i]);
        for ii = 1:numel(possibleSeeds)
            if ~ismember(possibleSeeds(ii),neib0)
                Map0(Map0==possibleSeeds(ii))=0;
            end
        end

        % watershed input
        scoreMap0 = scoreMap(rgh,rgw,rgl,rgt);
        BW = Map0==0;
        Map0(pix0) = 0;
        Map(pix) = 0;

        % separate regions to avoid connected seeds
        pix1 = find(Map0>0);
        [ih0,iw0,il0,it0] = ind2sub([H0,W0,L0,T0],pix1);
        for k = 1:numel(dx)
            ih = max(1,min(H0,ih0+dx(k)));
            iw = max(1,min(W0,iw0+dy(k)));
            il = max(1,min(L0,il0+dz(k)));
            it = max(1,min(T0,it0+dt(k)));
            pixCur = sub2ind([H0,W0,L0,T0],ih,iw,il,it);
            select = (Map0(pixCur) ~= Map0(pix1)) & Map0(pixCur)>0;
            Map0(pix1(select)) = 0;
            ih0 = ih0(~select);
            iw0 = iw0(~select);
            il0 = il0(~select);
            it0 = it0(~select);
            pix1 = pix1(~select);
        end
        
        if L==1
            BW = permute(BW,[1,2,4,3]);
            Map0 = permute(Map0,[1,2,4,3]);
            scoreMap0 = permute(scoreMap0,[1,2,4,3]);
        end
        BW2 = imerode(BW,SE);
        scoreMap0(BW) =  max(scoreMap0(pix0))+1;
        scoreMap0(BW2) = -100;
        scoreMap1 = imimposemin(scoreMap0,Map0>0|BW2);
        % marker-controlled splitting
        MapOut = watershed(scoreMap1);

        % fill the gap
        pix1 = pix0(MapOut(pix0)==0);
        while ~isempty(pix1)
            [ih0,iw0,il0,it0] = ind2sub([H0,W0,L0,T0],pix1);
            for k = 1:numel(dx)
                ih = max(1,min(H0,ih0+dx(k)));
                iw = max(1,min(W0,iw0+dy(k)));
                il = max(1,min(L0,il0+dz(k)));
                it = max(1,min(T0,it0+dt(k)));
                pixCur = sub2ind([H0,W0,L0,T0],ih,iw,il,it);
                select = MapOut(pixCur)>0;
                MapOut(pix1(select)) = MapOut(pixCur(select));
                ih0 = ih0(~select);
                iw0 = iw0(~select);
                il0 = il0(~select);
                it0 = it0(~select);
                pix1 = pix1(~select);
            end
        end

        if L==1
            MapOut = permute(MapOut,[1,2,4,3]);
        end

        % update
        MapOut(BW) = 0;
        waterLst = label2idx(MapOut);
        for ii = 1:numel(waterLst)
            curPix = waterLst{ii};
            curLabel = setdiff(Map0(curPix),0);
            if isempty(curLabel) 
                continue; 
            end

            % update
            curPix = intersect(curPix,pix0);
            if isempty(curPix)
                continue;
            end
            [ch,cw,cl,ct] = ind2sub([H0,W0,L0,T0],curPix);
            ch = ch + min(rgh) - 1;
            cw = cw + min(rgw) - 1;
            cl = cl + min(rgl) - 1;
            ct = ct + min(rgt) - 1;
            curPix = sub2ind([H,W,L,T],ch,cw,cl,ct);
            evtLst{curLabel} = [evtLst{curLabel};curPix];
            Map(curPix) = curLabel;
            majorUpdate = union(majorUpdate,curLabel);
        end
    end

    % update majority
    dF = reshape(dF,[],T);
    for j = 1:numel(majorUpdate)
        i = majorUpdate(j);
        if isempty(evtLst{i})
            continue;
        end
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

    sz = cellfun(@numel,evtLst);
    isGood = sz>0;
    majorityEvt0 = majorityEvt0(isGood);
    sdLst = sdLst(isGood);
    evtLst = evtLst(isGood);
end