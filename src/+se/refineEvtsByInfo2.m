function [evtLst,majorityEvt,mergingInfo,refineWork] = refineEvtsByInfo2(evtLst,seLabel,majorityEvt,dFOrg,dFSmoVec,mergingInfo,opts)
    N = numel(evtLst);
    nEvt = N;
    [H,W,T] = size(dFOrg);
    dFOrg = reshape(dFOrg,[],T);
    trivial = false(N,1);
    %% setting
    opts.refineMaxShift = 5;
    windowOverLap = 0.5;
    pValLimitation = 1e-3;
    smo = 2;
    ext = opts.minDur;
    %% refine: use neighbor event information
    % no use, for checking results
    
    refineCheckList = mergingInfo.refineCheckList;
    sourceLabels = zeros(N,1);
    sourceLst = [];
    for i = 1:N
        if(~refineCheckList(i)) % if already checked and no need to check again
            continue;
        end
        pix = evtLst{i};
        [ih,iw,it] = ind2sub([H,W,T],pix);
        t00 = min(it); t11 = max(it);
        curSPLabel = seLabel(i);

        % neighbor, but not same super event
        neibAll = mergingInfo.neibLst{i};
        belongSE = seLabel(neibAll);
        neibOut = neibAll(belongSE~=curSPLabel);
        neibIn = neibAll(belongSE==curSPLabel);

        curPeak = majorityEvt{i}.tPeak;
        nPeak = []; 
        for j = 1:numel(neibIn)
           nPeak = [nPeak;majorityEvt{neibIn(j)}.tPeak]; 
        end
        neibOut = union(neibOut,neibIn(abs(curPeak-nPeak)>numel(majorityEvt{i}.TW)/3));
        neibOut = neibOut(neibOut<=N);
        if(isempty(neibOut))
            continue;
        end

        % Peak Labels
        cntPeak = 1;

        ihw = majorityEvt{i}.ihw;
        evtIhw = unique(sub2ind([H,W],ih,iw));
        curve = mean(dFOrg(ihw,:),1);
        curveSmo = imgaussfilt(curve,smo);

        % conclude each super event
        neiIhws = cell(numel(neibOut),1);
        neiTWs = cell(numel(neibOut),1);
        for j = 1:numel(neibOut)
            nLabel = neibOut(j);
            neiIhws{j} = majorityEvt{nLabel}.ihw;
            neiTWs{j} = majorityEvt{nLabel}.TW;
        end
        %% from largest one
        szIhw = cellfun(@numel,neiIhws);
        [~,id] = sort(szIhw,'descend');
        neiIhws = neiIhws(id);
        neiTWs = neiTWs(id);
        neibOut = neibOut(id);

        detectedTW = [];
        % consider original peak maybe too large find peak point
        curTW = intersect(t00:t11,majorityEvt{i}.TW);
        left = false(numel(curTW),1);  left(2:end) = curveSmo(min(curTW)+1:max(curTW))>=curveSmo(min(curTW):max(curTW)-1);
        right = false(numel(curTW),1); right(1:end-1) = curveSmo(min(curTW):max(curTW)-1)>=curveSmo(min(curTW)+1:max(curTW));
        maxima = left & right; maxima = find(maxima); maxima = maxima + min(curTW) - 1;
        [~,id] = max(curveSmo(maxima));
        curTPEAK = maxima(id);
        
        peakPosition = [curTPEAK];
        detectedTW{1} = max(curTPEAK - ext,1):min(T,curTPEAK + ext);
        removeCurMajTW = setdiff(t00:t11,detectedTW{1});
        sLabel = zeros(T,1);
        % check whether share same trend
        for j = 1:numel(neibOut)
            nIhw = neiIhws{j};
            nCurve = mean(dFOrg(nIhw,:),1);
            nCurveSmo = imgaussfilt(nCurve,smo);
                      
            % Adjust time window
            nTW = extendTW(nCurveSmo,neiTWs{j},T);
            tNPeak = majorityEvt{neibOut(j)}.tPeak;
            alreadyDetect = false;
            for k = 1:cntPeak
                dTW = detectedTW{k};
                interTW = intersect(nTW,dTW);
                if(numel(interTW)/numel(dTW)>windowOverLap)
                    alreadyDetect = true;
                    break;
                end
            end
            if(alreadyDetect|| ~ismember(tNPeak,removeCurMajTW))
                continue;
            end
            % change NTW, only use overlap time window, small extend
            nTW = intersect(nTW,removeCurMajTW);
            t0s = tNPeak;
            for t = tNPeak:-1:1
                if(ismember(t,nTW))
                    t0s = t;
                else
                    break;
                end
            end
            t0e = tNPeak;
            for t = tNPeak:T
                if(ismember(t,nTW))
                    t0e = t;
                else
                    break;
                end
            end

            % neighbor peak limitation
            nPeakLimit = max(1,tNPeak - round(opts.minDur/2)) >= t0s & (min(T,tNPeak + round(opts.minDur/2))<=t0e);
            if(~nPeakLimit)
                continue;
            end
            nTW = t0s:t0e;
            
            % Use cut of the event
            ihwThisPart = se.getIhwThisPart(pix,nTW,[H,W,T],0.8);
            if(numel(ihwThisPart)<opts.minSize)
                continue;
            end
            curveThisPart = mean(dFOrg(ihwThisPart,:),1);
            curveThisPartSmo = imgaussfilt(curveThisPart,smo);
            
            % sliding window for correlation
            L = numel(nTW);
            alignTstart = max(1,min(nTW)-opts.refineMaxShift):(min(T,max(nTW)+opts.refineMaxShift)-L+1);
            alignList = alignTstart - min(nTW);

            curvesAlign = zeros(numel(alignList),L);
            for t = 1:numel(alignList)
                curvesAlign(t,:) = curveThisPart(alignTstart(t):alignTstart(t)+L-1);
            end
            curvesAlign = balanceCurves(curvesAlign);
            cor = corr(balanceCurves(nCurve(nTW))',curvesAlign');
            [r,id] = max(cor);
            zscore = r/sqrt(1-r^2)*sqrt(L-2);
            pVal = tcdf(zscore,L-2,'upper');
            
            % Smo
            curvesAlignSmo = zeros(numel(alignList),L);
            for t = 1:numel(alignList)
                curvesAlignSmo(t,:) = curveThisPartSmo(alignTstart(t):alignTstart(t)+L-1);
            end
            curvesAlignSmo = balanceCurves(curvesAlignSmo);
            corSmo = corr(balanceCurves(nCurveSmo(nTW))',curvesAlignSmo');
            [rSmo,idSmo] = max(corSmo);
            LSmo = round(L/2.2);
            zscore = rSmo/sqrt(1-rSmo^2)*sqrt(LSmo-2);
            pValSmo = tcdf(zscore,LSmo-2,'upper');
            if(pValSmo<pVal)
               pVal = pValSmo;
               id = idSmo;
            end
            
            if(pVal>=pValLimitation)
               continue; 
            end
            
            % t-test check
            curtPeak = tNPeak + alignList(id);
            curPeakTW = alignTstart(id):alignTstart(id)+L-1;
            curPeakTW = intersect(curPeakTW,t00:t11);
            if(numel(curPeakTW)<opts.minDur) continue; end
            extNeiPeakTW = max(1,curtPeak - round(opts.minDur/2)):min(T,curtPeak + round(opts.minDur/2));
            [tScoreCheck,curPeakForGap] = tScorecheckCurveWhetherContainPeak(curveThisPart,curPeakTW,extNeiPeakTW,opts);
                
            if(tScoreCheck)
                cntPeak = cntPeak + 1;
                removeCurMajTW = setdiff(removeCurMajTW,curPeakTW);
                detectedTW{cntPeak} = curPeakTW;
                peakPosition = union(peakPosition,curPeakForGap);
                sLabel(curPeakForGap) = neibOut(j);
%                 sourceL = [sourceL;neibOut(j)];
            end
        end

        peakForFindGap = peakPosition;

        % - Note: Here use the whole event footprint to find gap, since
        % split need to consider neighbor not significant region.
        evtcurveSmo = imgaussfilt(mean(dFOrg(evtIhw,:),1),smo);
        % find gap point
        GapPoint = [];
        for k = 1:(numel(peakForFindGap)-1)
            t0 = peakForFindGap(k);
            t1 = peakForFindGap(k+1);

            [~,tGap] = min(evtcurveSmo(t0+2:t1-2));
            tGap = tGap + t0 - 1;
            GapPoint = [GapPoint,tGap];
        end
        GapPoint = union(GapPoint,[t00,t11]);

        % minimum point for cut
        if(numel(GapPoint)>2)
            for k = 1:(numel(GapPoint) - 1)
                t0 = GapPoint(k) + 1;
                t1 = GapPoint(k+1);
                curtPeak = peakPosition(k);
                if(k==1) t0 = GapPoint(k); end
                select = it>=t0 & it<=t1;
                curPix = pix(select);
                if(ismember(curTPEAK,t0:t1))
                    evtLst{i} = curPix;
                    majorityEvt{i}.tPeak = curTPEAK;
                    majorityEvt{i}.TW = intersect(t0:t1,majorityEvt{i}.TW);    
                    majorityEvt{i}.needUpdatePeak = false;   % split, peak need to check
                    curve00 = mean(dFOrg(majorityEvt{i}.ihw,:),1); curve00 = curve00(majorityEvt{i}.TW);
%                     curve00 = curve00 - ([0:numel(curve00)-1]/numel(curve00)*(curve00(end)-curve00(1))+curve00(1));
                    curve00 = curve00 - min(curve00);
                    curve00 = curve00/max(curve00(:));
                    majorityEvt{i}.curve = curve00;
                    sourceLst = [sourceLst,i];
                else
                   [mIhw,TW,delays] = se.getRefineSpaMajority_Ac(ihw,dFSmoVec,[H,W,T],curPix,t0:t1,opts,false);
                    % check trivial
                    nEvt = nEvt+1;  
                    trivial(nEvt) = numel(mIhw)<=opts.minSize;
                    evtLst{nEvt} = curPix;
                    seLabel(nEvt) = nEvt;
                    majorityEvt{nEvt}.ihw = mIhw;
                    majorityEvt{nEvt}.TW = TW;
                    majorityEvt{nEvt}.delays = delays;
                    majorityEvt{nEvt}.needUpdatePeak = false;   % peak follow others
                    majorityEvt{nEvt}.tPeak = curtPeak;
                    curve00 = mean(dFOrg(mIhw,:),1); curve00 = curve00(TW);
%                     curve00 = curve00 - ([0:numel(curve00)-1]/numel(curve00)*(curve00(end)-curve00(1))+curve00(1));
                    curve00 = curve00 - min(curve00);
                    curve00 = curve00/max(curve00(:));
                    majorityEvt{nEvt}.curve = curve00;
                    sourceLabels(nEvt) = sum(sLabel(t0:t1));
                    mergingInfo.evtCCLabel(nEvt) = mergingInfo.evtCCLabel(i);
                end
            end
        end
    end

    growLst = [];
    for i = (N+1):nEvt
       if(trivial(i))    % is trivial event. Too small majority, merge
            pix = evtLst{i};
            label = sourceLabels(i);
            evtLst{i} = [];
            evtLst{label} = [evtLst{label};pix];
            sourceLst = union(sourceLst,sourceLabels(i));
            growLst = [growLst,label];
       end
    end
    
    % final result
    majorityEvt = majorityEvt(~trivial);
    evtLst = evtLst(~trivial);
    mergingInfo.evtCCLabel = mergingInfo.evtCCLabel(~trivial);
    refineWork = nEvt>N;
    
    % update connected component region info
    newEvtLst = (N+1):numel(evtLst);
    for i = (N+1):numel(evtLst)
       ccLabel =  mergingInfo.evtCCLabel(i);
       mergingInfo.labelsInActRegs{ccLabel} = [mergingInfo.labelsInActRegs{ccLabel};i];
    end
    
    mergingInfo.sourceLst = sourceLst;
    mergingInfo.growLst = growLst;
    mergingInfo.newEvtLst = newEvtLst;
end

function [tScoreCheck,tPeak] = tScorecheckCurveWhetherContainPeak(curve,curPeakTW,extNeiPeakTW,opts)
tScoreCheck = false;
    T = numel(curve);
    tPeak = [];
    curveSmo = imgaussfilt(curve,2);
    gap = opts.smoT*2+1;
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
           if(min(Tscore1,Tscore2)>=0) % T-test check
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