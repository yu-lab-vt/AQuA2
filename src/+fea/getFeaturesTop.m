function [ftsLst,dffMat,dMat,dffAlignedMat] = getFeaturesTop(dat,evtLst,opts,ff)
% ----------- Modified by Xuelong Mi, 04/04/2023 -----------
    % getFeaturesTop extract curve related features, basic features
    % dat: single (0 to 1)
    % evtMap: single (integer)
    
    [H,W,L,T] = size(dat);
    evtMap = zeros(size(dat),'uint16');
    for ii=1:numel(evtLst)
        evtMap(evtLst{ii}) = ii;
    end
    
    secondPerFrame = opts.frameRate;
    muPerPix = opts.spatialRes;
    
    % impute events
    fprintf('Imputing ...\n')
    datx = dat;
    datx(evtMap>0) = nan;
    dat = reshape(dat,[],T);
    datx = reshape(datx,[],T);
    datx = img.imputeMov(datx);    
    Tww = opts.movAvgWin;
    
    if exist('ff','var')&&~isempty(ff)
        waitbar(0.1, ff);
    end

    ftsLst = [];
    ftsLst.basic = [];
    ftsLst.propagation = [];
    
    foptions = fitoptions('exp1');
    foptions.MaxIter = 100;
    dMat = zeros(numel(evtLst),T,2,'single');
    dffMat = zeros(numel(evtLst),T,2,'single');
    alignedrgT = -10:100;
    dffAlignedMat = nan(numel(evtLst),111,'single');

    for ii=1:numel(evtLst)
        if exist('ff','var')&&~isempty(ff) && mod(ii,100)==0 
            fprintf('%d/%d\n',ii,numel(evtLst))
            waitbar(0.1 + 0.2*ii/numel(evtLst), ff);
        end
        pix0 = evtLst{ii};
        if isempty(pix0)
            continue
        end
        [ih,iw,il,it] = ind2sub([H,W,L,T],pix0);
        ihw = unique(sub2ind([H,W,L],ih,iw,il));
        rgT = min(it):max(it);
%         if numel(rgT)==1
%             continue
%         end
        
        % dff
        charx1 = mean(dat(ihw,:),1);
        sigma1 = pre.avgDatNoiseEst(charx1,ihw,opts);
        
        % correct baseline method
        charxBg1 = getBaseline(charx1,Tww,opts.cut);
        charxBg1 = charxBg1 - pre.obtainBias(Tww,opts.cut)*sigma1;
        dff1 = (charx1-charxBg1)./(charxBg1+1e-4);
        % may be modified later
        sigma1dff = max(1e-4,sqrt(mean((dff1(2:end)-dff1(1:end-1)).^2)/2));

        dff1Sel = dff1(rgT);
        dffMax1= max(dff1Sel);
        
        % dff without other events
        charx2 = mean(datx(ihw,:),1,'omitnan');
        charx2(rgT) = charx1(rgT);
        dff2 = (charx2-charxBg1)./(charxBg1+1e-4);        
        
        % for p values
        dff2Sel = dff2(rgT);
        [dffMax2,tMax] = max(dff2Sel);
        xMinPre = min(dff2Sel(1:tMax));
        xMinPost = min(dff2Sel(tMax:end));
        dffMaxZ = max((dffMax2-xMinPre+dffMax2-xMinPost)/sigma1dff/2,0);
        dffMaxPval = 1-normcdf(dffMaxZ);
    
        % extend event window in the curve
        [dff1e,rgT1] = fea.extendEventTimeRangeByCurve(dff1,charx1~=charx2,rgT);
        
        % curve features
        [ rise19,fall91,width55,width11,decayTau,pp,riseTime] = fea.getCurveStat( ...
            dff1e, secondPerFrame, foptions, opts.ignoreTau );
        riseTime = riseTime + min(rgT1) - 1;

        dffMat(ii,:,1) = single(dff1);
        dffMat(ii,:,2) = single(dff2);
        dMat(ii,:,1) = single(charx1)*(opts.maxValueDat - opts.minValueDat) + opts.minValueDat; 
        dMat(ii,:,2) = single(charx2)*(opts.maxValueDat - opts.minValueDat) + opts.minValueDat; 
        
        % update
        ftsLst.loc.t0(ii) = min(it);
        ftsLst.loc.t1(ii) = max(it);
        ftsLst.curve.tBegin(ii) = min(it);
        ftsLst.curve.tEnd(ii) = max(it);
        ftsLst.loc.xSpaTemp{ii} = pix0;
        ftsLst.loc.xSpa{ii} = ihw;
        ftsLst.curve.rgt1(ii,:) = [min(rgT1),max(rgT1)];        % extended time window
        ftsLst.curve.dffMax(ii) = dffMax1;
        ftsLst.curve.dffMax2(ii) = dffMax2;
        ftsLst.curve.dffMaxFrame(ii) = (tMax+min(rgT)-1);
        ftsLst.curve.dffMaxZ(ii) = dffMaxZ;
        ftsLst.curve.dffMaxPval(ii) = dffMaxPval;
        ftsLst.curve.duration(ii) = (max(it)-min(it)+1)*secondPerFrame;
        ftsLst.curve.rise19(ii) = rise19;   % seconds
        ftsLst.curve.fall91(ii) = fall91;   % seconds
        ftsLst.curve.width55(ii) = width55; % seconds
        ftsLst.curve.width11(ii) = width11; % seconds
        ftsLst.curve.decayTau(ii) = decayTau;
        ftsLst.curve.riseTime(ii) = riseTime;   % Frame
        ftsLst.curve.dff1Begin(ii) = (pp(1,1)+min(rgT1)-1); % Frame
        ftsLst.curve.dff1End(ii) = (pp(1,2)+min(rgT1)-1);   % Frame
        
        
        %% new feature
        % curve from 10 frame previous to 10% rising, to next 100 frames following 10% rising
        t0 = min(rgT1) + pp(1,1) - 1;
        range = alignedrgT+t0;
        valid = range>0 & range<=T;
        dffAlignedMat(ii,11+alignedrgT(valid)) = dff1(range(valid));
         
        % AUC
        ftsLst.curve.datAUC(ii) = sum(charx1(min(it):max(it)));
        ftsLst.curve.dffAUC(ii) = sum(dff1(min(it):max(it)));
        
        % basic features
        rgH = max(min(ih)-1,1):min(max(ih)+1,H);
        rgW = max(min(iw)-1,1):min(max(iw)+1,W);
        rgL = max(min(il)-1,1):min(max(il)+1,L);
        ih1 = ih-min(rgH)+1;
        iw1 = iw-min(rgW)+1;
        il1 = il-min(rgL)+1;
        voxi = false(length(rgH),length(rgW),length(rgL));
        pix1 = unique(sub2ind(size(voxi),ih1,iw1,il1));
        voxi(pix1) = true;
        ftsLst.basic.center{ii} = [round(mean(ih)), round(mean(iw)), round(mean(il))];
        ftsLst.basic = fea.getBasicFeatures(voxi,muPerPix,ii,ftsLst.basic);
    end
    
    ftsLst.bds = img.getEventBorder(evtLst,[H,W,L,T]);
    if L==1
        ftsLst.notes.propDirectionOrder = {'Anterior', 'Posterior', 'Left', 'Right'};
    else
        ftsLst.notes.propDirectionOrder = {'+X', '-X', '+Y', '-Y', '+Z', '-Z'};
    end
    
end

function F0 = getBaseline(x0,window,cut)
    datMA = movmean(x0,window);
    T = numel(datMA);
    step = round(0.5*cut);
    nSegment = max(1,ceil(T/step)-1);

    F0 = zeros(size(x0));
    for k = 1:nSegment
        t0 = 1 + (k-1)*step;
        t1 = min(T,t0+cut);
        
        [curMinV,curMinT] = min(datMA(t0:t1));
        curMinT = curMinT + t0 - 1;
        if(k==1)
            F0(1:curMinT) = curMinV;
        else
            F0(preMinT:curMinT) = preMinV + (curMinV-preMinV)/(curMinT-preMinT)*[0:curMinT-preMinT]; 
        end      
        if(k==nSegment)
            F0(curMinT:end) = curMinV;
        end
        preMinT = curMinT;
        preMinV = curMinV;
    end
end