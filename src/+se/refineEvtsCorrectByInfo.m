function [evtLst,majorityEvt,mergingInfo,refineWork] = refineEvtsCorrectByInfo(evtLst,seLabel,majorityEvt,dFOrg,dFSmoVec,mergingInfo,opts)
    N = numel(evtLst);
    nEvt = N;
    [H,W,T] = size(dFOrg);
    dFOrg = reshape(dFOrg,[],T);
    %% setting
    opts.refineMaxShift = 5;
    ext = opts.minDur;
    %% refine: use neighbor event information
    % no use, for checking results
    sourceLst = [];
    for i = 1:N
        pix = evtLst{i};
        [ih,iw,it] = ind2sub([H,W,T],pix);
        t00 = min(it); t11 = max(it);
        curSPLabel = seLabel(i);

        % neighbor, but not same super event
        neib0 = mergingInfo.neibLst{i};
        neib0 = neib0(neib0<=N);
        belongSE = seLabel(neib0);
        neibOut = neib0(belongSE~=curSPLabel);
        if(isempty(neibOut))
            continue;
        end
        
        curMajCurve = imgaussfilt(mean(dFOrg(majorityEvt{i}.ihw,:)),2);
        curTWSeed = max(1,majorityEvt{i}.tPeak-round(ext/2)):min(T,majorityEvt{i}.tPeak+round(ext/2));
        curTW = se.getMajorityTem(curMajCurve,curTWSeed,pix,[H,W,T]);

        removeCurMajTW = setdiff(t00:t11, curTW);
        % check whether share same trend
        for j = 1:numel(neibOut)
            nLabel = neibOut(j);
            nPix = evtLst{nLabel};
            [~,~,nit] = ind2sub([H,W,T],evtLst{nLabel});
            
            nMajCurve = imgaussfilt(mean(dFOrg(majorityEvt{nLabel}.ihw,:)),2);
            nTWSeed = max(1,majorityEvt{nLabel}.tPeak-round(ext/2)):min(T,majorityEvt{nLabel}.tPeak+round(ext/2));
            nTW = se.getMajorityTem(nMajCurve,nTWSeed,pix,[H,W,T]);
            
            removeNeiCurMajTW = setdiff(min(nit):max(nit), nTW);
            commonTW = intersect(removeCurMajTW,removeNeiCurMajTW);
            if(isempty(commonTW)) continue; end
            % get component
            gS = find(commonTW(2:end)-commonTW(1:end-1)>1);
            gS = union([0,numel(commonTW)],gS);
            
            TWs = cell(numel(gS)-1,1);
            for k = 1:numel(gS)-1
               t0 = commonTW(gS(k)+1);
               t1 = commonTW(gS(k+1));
               TWs{k} = t0:t1;
            end
            sz = cellfun(@numel,TWs);
            TWs = TWs(sz>opts.minDur);
            
            for k = 1:numel(TWs)
                TW = TWs{k};
                ihwThisPart = se.getIhwThisPart(pix,TW,[H,W,T],0.8);
                if(numel(ihwThisPart)<opts.minSize)
                    continue;
                end
                nIhwThisPart = se.getIhwThisPart(nPix,TW,[H,W,T],0.8);
                if(numel(nIhwThisPart)<opts.minSize)
                    continue;
                end
                curve = mean(dFOrg(ihwThisPart,:),1);
                nCurve = mean(dFOrg(nIhwThisPart,:),1);
                [tScoreCheck1,tP1] = tScorecheckCurveWhetherContainPeak(curve,TW,TW,opts);
                if (~tScoreCheck1)
                    continue;
                end
                [tScoreCheck2,tP2] = tScorecheckCurveWhetherContainPeak(nCurve,TW,TW,opts);
                if (~tScoreCheck2)
                    continue;
                end
                r = corr(balanceCurves(curve(TW))',nCurve(TW)');
                if(r<0.6)
                    continue;
                end
                %% update
                % split event 1
                if(tP1>majorityEvt{i}.tPeak)
                    [~,tSplit] = min(curve(majorityEvt{i}.tPeak:tP1));
                    tSplit = majorityEvt{i}.tPeak + tSplit - 1;
                    select = it>=tSplit;
                else
                    [~,tSplit] = min(curve(tP1:majorityEvt{i}.tPeak));
                    tSplit = tP1 + tSplit - 1;
                    select = it<=tSplit;
                end
                
                ccLabel = mergingInfo.evtCCLabel(i);
%                 select = it>=min(TW) & it<=max(TW);
                pix0 = pix(select);
                nEvt = nEvt + 1;
%                 Map(pix0) = nEvt;
                evtLst{i} = pix(~select);
                majorityEvt{i}.TW = intersect(min(it(~select)):max(it(~select)),majorityEvt{i}.TW);    % may have issue
                curve00 = mean(dFOrg(majorityEvt{i}.ihw,:),1); curve00 = curve00(majorityEvt{i}.TW);
                curve00 = curve00 - min(curve00);
                curve00 = curve00/max(curve00(:));
                majorityEvt{i}.curve = curve00;
                
                evtLst{nEvt} = pix0;
                removeCurMajTW = setdiff(removeCurMajTW,TW);
                [mIhw,TW,delays] = se.getRefineSpaMajority2(ihwThisPart,dFSmoVec,[H,W,T],pix0,TW,opts,false);
                seLabel(nEvt) = nEvt;
                majorityEvt{nEvt}.ihw = mIhw;
                majorityEvt{nEvt}.TW = TW;
                majorityEvt{nEvt}.delays = delays;
                majorityEvt{nEvt}.needUpdatePeak = false;
                majorityEvt{nEvt}.tPeak = tP1;
                curve00 = mean(dFOrg(mIhw,:),1); curve00 = curve00(TW);
                curve00 = curve00 - min(curve00);
                curve00 = curve00/max(curve00(:));
                majorityEvt{nEvt}.curve = curve00;
                sourceLst = [sourceLst;i];
                mergingInfo.evtCCLabel(nEvt) = ccLabel;
                mergingInfo.labelsInActRegs{ccLabel} = [mergingInfo.labelsInActRegs{ccLabel};nEvt];
                
                if(tP2>majorityEvt{nLabel}.tPeak)
                    [~,tSplit] = min(nCurve(majorityEvt{nLabel}.tPeak:tP2));
                    tSplit = majorityEvt{nLabel}.tPeak + tSplit - 1;
                    select = nit>=tSplit;
                else
                    [~,tSplit] = min(nCurve(tP2:majorityEvt{nLabel}.tPeak));
                    tSplit = tP2 + tSplit - 1;
                    select = nit<=tSplit;
                end
%                 select = nit>=min(TW) & nit<=max(TW);
                nPix0 = nPix(select);
                nEvt = nEvt + 1;
%                 Map(nPix0) = nEvt;
                evtLst{nLabel} = nPix(~select);
                evtLst{nEvt} = nPix0;
                majorityEvt{nLabel}.TW = intersect(min(nit(~select)):max(nit(~select)),majorityEvt{nLabel}.TW);    % may have issue
                curve00 = mean(dFOrg(majorityEvt{nLabel}.ihw,:),1); curve00 = curve00(majorityEvt{nLabel}.TW);
                curve00 = curve00 - min(curve00);
                curve00 = curve00/max(curve00(:));
                majorityEvt{nLabel}.curve = curve00;
                
                [mIhw,TW,delays] = se.getRefineSpaMajority2(nIhwThisPart,dFSmoVec,[H,W,T],nPix0,TW,opts,false);
                majorityEvt{nEvt}.ihw = mIhw;
                majorityEvt{nEvt}.TW = TW;
                majorityEvt{nEvt}.delays = delays;
                majorityEvt{nEvt}.needUpdatePeak = false;
                majorityEvt{nEvt}.tPeak = tP2;
                curve00 = mean(dFOrg(mIhw,:),1); curve00 = curve00(TW);
                curve00 = curve00 - min(curve00);
                curve00 = curve00/max(curve00(:));
                majorityEvt{nEvt}.curve = curve00;
                sourceLst = [sourceLst;nLabel];
                mergingInfo.evtCCLabel(nEvt) = ccLabel;  
                mergingInfo.labelsInActRegs{ccLabel} = [mergingInfo.labelsInActRegs{ccLabel};nEvt];
            end
        end
    end
    
    refineWork = nEvt>N;
    newEvtLst = N+1:nEvt;
    mergingInfo.sourceLst = sourceLst;
    mergingInfo.newEvtLst = newEvtLst;
end

function [tScoreCheck,tPeak] = tScorecheckCurveWhetherContainPeak(curve,curPeakTW,extNeiPeakTW,opts)
    tScoreCheck = false;
    T = numel(curve);
    tPeak = [];
    curveSmo = imgaussfilt(curve,0.001);
    gap = 2*opts.smoT+1;
    s0 = sqrt(median((curveSmo(gap+1:end)-curveSmo(1:end-gap)).^2)/0.9133);
    curveSmo = curveSmo/s0;
    thrs = (max(curveSmo(curPeakTW))):-opts.step:min(curveSmo(curPeakTW));
    thisTW = false(T,1);
    thisTW(curPeakTW) = true;
    containNeiPeak = false(T,1);
    containNeiPeak(extNeiPeakTW) = true;
    for k = 1:numel(thrs)
       thr = thrs(k);
       curTWs = bwconncomp((curveSmo>thr) & thisTW');
       curTWs = curTWs.PixelIdxList;
       sz = cellfun(@numel,curTWs);
       curTWs = curTWs(sz>=3);
        for j = 1:numel(curTWs)
           TW = curTWs{j};
           %% Double -ide check
           t0 = TW(1);
           t1 = TW(end);
           
           % whether belong to current event
           if(isempty(find(containNeiPeak(t0:t1),1))  || t0==curPeakTW(1) || t1==curPeakTW(end) )
              continue; 
           end
           [~,tPeak] = max(curveSmo(TW));
            tPeak = tPeak + min(TW) - 1;
            
            
           if(~containNeiPeak(tPeak)) 
               if(t0<=extNeiPeakTW(1) && t1>=extNeiPeakTW(end)) % the peak is out of timewindow
                tPeak = [];
                return;   
               else
                continue;
               end
           end
           fg = curveSmo(TW);
           [bg1,bg2] = se.findNeighbor(curveSmo,t0,t1,T,thr,curveSmo);
           [Tscore1,Tscore2] = se.calTScore(fg,bg1,bg2);
           if(min(Tscore1,Tscore2)>=3) % T-test check
              tScoreCheck = true;
              return; 
           end
           
           
        end
    end
    if(~tScoreCheck)
        tPeak = [];
    end
end
function TW = extendTW(curve,TW,T)
    t0 = TW(1);
    t1 = TW(end);
    while(t0>1 && curve(t0-1)<curve(t0))
        t0 = t0-1;
    end
    while(t1<T && curve(t1+1)<curve(t1))
        t1 = t1+1;
    end
    TW = t0:t1;
end
function curves = balanceCurves(curves)
    [N,T] = size(curves);
    for i = 1:N
       curve0 = curves(i,:);
       curve0Smo = imgaussfilt(curve0,2);
       t0 = 1;
       t1 = T;
       % find left local minima
       while(t0<T && curve0Smo(t0)>curve0Smo(t0+1))
           t0 = t0+1;
       end
       while(t1>1 && curve0Smo(t1)>curve0Smo(t1-1))
           t1 = t1-1;
       end
       if(t1-t0<3)
          t0 = 1;t1 = T; 
       end
       
       baseline = curve0(t0) + (curve0(t1)-curve0(t0))/(t1-t0)*([1:T]-t0);
       curves(i,:) = curve0 - baseline;
    end
end