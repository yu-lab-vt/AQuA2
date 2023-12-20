function [evt2Lst,major,sdLst] = splitEvt_Ac(dF,datOrg,evtLst,sdLst,major,opts)

    [H,W,L,T] = size(datOrg);
    step = 0.05;

    %% get Majority
    N = numel(major);    
    trivial = false(N,1);

    %% Split
    Map = zeros(H,W,L,T,'uint16');
    for i = 1:numel(evtLst)
       Map(evtLst{i})  = i;
    end

    datVecOrg = reshape(datOrg,[],T);
    clear dFOrg;
    dFVec = reshape(dF,[],T);
    clear dF;
    Map = reshape(Map,[],T);
    evtVecLst = label2idx(Map);
    nEvt = N;
    minDur = opts.minDur;

    sourceEvt = 1:N;
    for i = 1:N
       pix = evtVecLst{i} ;
       [~,~,~,it00] = ind2sub([H,W,L,T],pix);
       ihw = major{i}.ihw;
       curve = mean(datVecOrg(major{i}.ihw,:),1);
       s0 = pre.avgDatNoiseEst(curve,ihw,opts);
       curve = curve/s0;
       curveSmo = imgaussfilt(curve,2);
       t00 = min(it00);
       t11 = max(it00);

       % initialization
       thrs = max(curveSmo(t00:t11)):-step:min(curveSmo(t00:t11));
       labels = true(T,1);
       labels(t00:t11) = false;
       TWcandidate = cell(0);
       cnt = 0;     % peak number

       %% check significant peak
       for k = 1:numel(thrs)
           thr = thrs(k);
           curTWs = bwconncomp(curveSmo(t00:t11)>thr);
           curTWs = curTWs.PixelIdxList;
           sz = cellfun(@numel,curTWs);
           curTWs = curTWs(sz>=minDur);
            
           for j = 1:numel(curTWs)
               TW = curTWs{j} + t00 - 1;
               t0 = TW(1);
               t1 = TW(end);
               if(t0==t00 && t00>1 && curveSmo(t00-1)<thr) % left side
                   continue;
               end
               if(t1==t11 && t11<T && curveSmo(t11+1)<thr) % right side
                   continue;
               end
               
               % whether already detected
               if(~isempty(find(labels(t0:t1),1)))
                  continue; 
               end
               fg = curve(TW);
               [bg1,bg2,nv1,nv2] = se.findNeighbor(curve,t0,t1,T,thr,curveSmo);
               [Tscore1,Tscore2] = se.calTScore(fg,bg1,bg2);
               if(Tscore1<=opts.sigThr || Tscore2<=opts.sigThr) % T-test check, fail
                  continue; 
               end
               [score1,score2] = se.calOrderScore(fg,bg1,bg2,nv1,nv2);           
               if(min(score1,score2)>opts.sigThr)    % Update
                    cnt = cnt + 1;
                    TWcandidate{cnt} = t0:t1;
                    labels(TW) = true;
               end
           end
       end

       if(numel(TWcandidate)<=1)    % from average curve, no multiple significant peaks. No need to segment.
          continue; 
       end
              
        % find splitting margin
        tStart = cellfun(@(x)x(1),TWcandidate);
        [~,id] = sort(tStart);
        TWcandidate = TWcandidate(id);
        GapPoint = [];
        for k = 1:(numel(TWcandidate)-1)
            t0 = TWcandidate{k}(end) + 1;
            t1 = TWcandidate{k+1}(1) - 1;
            [~,tGap] = min(curveSmo(t0:t1));
            tGap = tGap + t0 - 1;
            GapPoint = [GapPoint;tGap];
        end

        % Extend each interval, check whether they are valid
        seedTW = major{i}.TW;
        GapPoint = [t00-1;GapPoint;t11];
        validGap = true(numel(GapPoint),1);
        validPeak = true(numel(GapPoint)-1,1);
        % check
        for k = 1:(numel(GapPoint)-1)
            TW = (GapPoint(k)+1):GapPoint(k+1);

            %% check whether significant
            t0 = min(TW);
            t1 = max(TW);
            [maxV,tPeak] = max(curveSmo(TW));
            tPeak = t0 + tPeak - 1;
            [minVLeft] = min(curveSmo(t0:tPeak));
            [minVRight] = min(curveSmo(tPeak:t1));
            minV = max(minVLeft,minVRight);
            if(maxV-minV<3)
                validPeak(k) = false;
                if(k+1 == numel(GapPoint))
                    t = k;
                    while(~validGap(t))
                        t = t-1;
                    end
                    validGap(t) = false;
                else
                    validGap(k+1) = false;
                end
            end
       end
       TWcandidate = TWcandidate(validPeak);
       GapPoint = GapPoint(validGap);
       
       % from average curve, no multiple significant peaks. No need to segment.
       if(numel(TWcandidate)<=1)
            continue;
       end

       szT = cellfun(@(x)numel(intersect(x,seedTW)),TWcandidate);
       [~,id] = max(szT);
       flag = true;
       for k = 1:numel(TWcandidate)            
           t0 = GapPoint(k)+1;
           t1 = GapPoint(k+1);
           select = it00>=t0 & it00<=t1;
           ts0 = TWcandidate{k}(1);   % update time window
           ts1 = TWcandidate{k}(end);

           % such segmentation could make region not connected
           pix0 = pix(select);  
           [ih,iw,il,it] = ind2sub([H,W,L,T],pix0);
           rgh = min(ih):max(ih); H0 = numel(rgh); ih = ih - min(ih) + 1;
           rgw = min(iw):max(iw); W0 = numel(rgw); iw = iw - min(iw) + 1;
           rgl = min(il):max(il); L0 = numel(rgl); il = il - min(il) + 1;
           rgt = min(it):max(it); T0 = numel(rgt); it = it - min(it) + 1;
           pix1 = sub2ind([H0,W0,L0,T0],ih,iw,il,it);
           Map0 = false(H0,W0,L0,T0);
           Map0(pix1) = true;
           cc = bwconncomp(Map0).PixelIdxList;

           if k==id
               sz = cellfun(@numel,cc);
               [~,ord] = sort(sz,'descend');
               cc = cc(ord);
           end

           for j = 1:numel(cc)
               [ih0,iw0,il0,it0] = ind2sub([H0,W0,L0,T0],cc{j});
               ih0 = ih0 + min(rgh) - 1;
               iw0 = iw0 + min(rgw) - 1;
               il0 = il0 + min(rgl) - 1;
               it0 = it0 + min(rgt) - 1;
               pix2 = sub2ind([H,W,L,T],ih0,iw0,il0,it0);

               %% majorPeak
               if(k==id && flag)
                    major{i}.TW = se.getMajorityTem(curve,ts0,ts1,t0,t1);
                    Map(pix2) = i;
                    curve00 = mean(datVecOrg(major{i}.ihw,:),1); curve00 = curve00(major{i}.TW);
                    curve00 = curve00 - min(curve00);
                    curve00 = curve00/max(curve00(:));
                    major{i}.curve = curve00;
                    flag = false;
               else
                    newSeedIhw = se.getInitIhwInSplit(curve,dFVec,[H,W,L,T],pix2,ts0,ts1,opts);
                    nEvt = nEvt+1;  
                    if isempty(newSeedIhw)
                        mIhw = [];
                        TW = t0:t1;
                        delays = [];
                    else
                        [mIhw,TW,delays] = se.seed2Majoirty(newSeedIhw,dFVec,[H,W,L,T],pix2,ts0,ts1,opts);
                    end
                   % check trivial
                    n0 = numel(intersect(ihw,mIhw));
                    n1 = numel(ihw);
                    n2 = numel(mIhw); 
                    
                    trivial(nEvt) = ~(n0/n1>=opts.overlap & n0/n2>=opts.overlap);
                    sourceEvt(nEvt) = i;
                    major{nEvt}.TW = TW;
                    major{nEvt}.ihw = mIhw;
                    major{nEvt}.delays = delays;
                    sdLst{nEvt} = sdLst{i};
                    curve00 = mean(datVecOrg(mIhw,:),1); curve00 = curve00(TW);
                    curve00 = curve00 - min(curve00);
                    curve00 = curve00/max(curve00(:));
                    major{nEvt}.curve = curve00;
                    Map(pix2) = nEvt;
               end
           end
       end 
    end
    
    Map = reshape(Map,[H,W,L,T]);
    evt2Lst = label2idx(Map);
    for i = 1:nEvt
        curSdPix = intersect(sdLst{i},evt2Lst{i});
        if isempty(curSdPix)
            curSdPix = evt2Lst{i};
        end
        sdLst{i} = curSdPix;
    end


    [dh,dw,dl] = se.dirGenerate(26); 
    [x_dir,y_dir,z_dir,t_dir] = se.dirGenerate(80); 
    % trivial should be merged before merging step
    % to avoid wrong forbidden pair
    % And from principle, it should have large overlap with its source
    for i = (N+1):nEvt
       if(trivial(i))    % is trivial event
            pix = evt2Lst{i};
            [ih,iw,il,it] = ind2sub([H,W,L,T],pix);
            curTW = major{i}.TW;
            neib0 = [];
            % Find neighbors
            for ii=1:numel(dh)
                ih1 = min(max(ih + dh(ii),1),H);
                iw1 = min(max(iw + dw(ii),1),W);
                il1 = min(max(il + dl(ii),1),L);
                vox1 = sub2ind([H,W,L,T],ih1,iw1,il,it);
                idxSel = setdiff(Map(vox1),[0,i]);
                neib0 = union(neib0,idxSel);
            end
            neib0 = neib0(neib0<=N);
            
            mergedLabel = [];
            if(~isempty(neib0))
                tOs = zeros(numel(neib0),1); 
                for k = 1:numel(neib0)
                    nLabel = neib0(k);
                    nTW = major{nLabel}.TW;
                    tOs(k) = numel(intersect(curTW,nTW))/numel(union(curTW,nTW));
                end
                [~,id] = max(tOs);
                if(tOs(id)>0.8)
                    mergedLabel = neib0(id);
                end
            end
            
            if(~isempty(mergedLabel))
                Map(pix) = mergedLabel;
                evt2Lst{i} = [];
                evt2Lst{mergedLabel} = [evt2Lst{mergedLabel};pix];
                % Update
                [mIhw,TW,delays] = se.seed2Majoirty(major{mergedLabel}.ihw,dFVec,[H,W,L,T],evt2Lst{mergedLabel},major{mergedLabel}.TW(1),major{mergedLabel}.TW(end),opts);
                major{mergedLabel}.TW = TW;
                major{mergedLabel}.ihw = mIhw;
                major{mergedLabel}.delays = delays;
                curve00 = mean(datVecOrg(mIhw,:),1); curve00 = curve00(TW);
                curve00 = curve00 - min(curve00);
                curve00 = curve00/max(curve00(:));
                major{mergedLabel}.curve = curve00;
            else    % no neighbor with overlapped time window
                if numel(major{i}.ihw) < opts.minSize
                    % too small. pick one region to merge
                    candidate = [];
                    for k = 1:numel(x_dir)
                        ih1 = max(1,min(H,ih+x_dir(k)));
                        iw1 = max(1,min(W,iw+y_dir(k)));
                        il1 = max(1,min(L,il+z_dir(k)));
                        it1 = max(1,min(T,it+t_dir(k)));
                        pixCur = sub2ind([H,W,L,T],ih1,iw1,il1,it1);
                        candidate = setdiff(Map(pixCur),[0,i]);
                        if ~isempty(candidate)
                            break;
                        end
                    end
                    if isempty(candidate)
                        continue;
                    end
                    evt2Lst{candidate(1)} = [evt2Lst{candidate(1)};pix];
                    Map(pix) = candidate(1);
                else
                    trivial(i) = false;
                end
            end
       end
    end
    
    major = major(~trivial);
    evt2Lst = evt2Lst(~trivial);
    sdLst = sdLst(~trivial);
end