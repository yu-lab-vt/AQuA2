function [cfuInfo1, cfuInfo2] = CFUdetectScript(res,cfuOpts)
    opts = res.opts;
    evtLst1 = res.evt1;
    [cfu_pre1] = cfu.CFU_tmp_function(evtLst1,true,opts.sz);
    if(~opts.singleChannel)
        evtLst2 = res.evt2;
        [cfu_pre2] = cfu.CFU_tmp_function(evtLst2,true,opts.sz);
    end
    alpha = cfuOpts.cfuDetect.overlapThr1;
    minNumEvt = cfuOpts.cfuDetect.minNumEvt1;
    [cfuRegions1,CFU_lst1] = cfu.CFU_minMeasure(cfu_pre1,true(numel(cfu_pre1.evtIhw),1),[],opts.sz,alpha,minNumEvt,false);
    datOrg1 = res.datOrg1;
    [H,W,L,T] = size(datOrg1);
    datVec = single(reshape(datOrg1,[],T));
    clear datOrg1;
    cfuCurves1 = zeros(numel(cfuRegions1),T);
    cfuDFFCurves1 = zeros(numel(cfuRegions1),T);
    for i = 1:numel(cfuRegions1)
        weightMap = cfuRegions1{i};
        weightMap = weightMap(:);
        idx = find(weightMap>0);
        cfuCurves1(i,:) = weightMap(idx)'*double(datVec(idx,:))/sum(weightMap);
        cfuDFFCurves1(i,:) = getdFF(cfuCurves1(i,:), opts.movAvgWin, opts.cut);
    end

    % rising time judgement
    thrVec = 0.4:0.1:0.6;
    cfuOccurrence1 = false(numel(CFU_lst1),T);
    cfuMapVideo = zeros(H,W,L,T,'uint16');
    nCFU = numel(cfuRegions1);
    for i = 1:nCFU
        evtInCFU = CFU_lst1{i};
        for j = 1:numel(evtInCFU)
            label = evtInCFU(j);
            cfuMapVideo(evtLst1{label}) = i;
        end
    end
    
    cfuMapVideo = reshape(cfuMapVideo,[],T);
    cfuTimeWindow1 = false(nCFU,T);
    cfuNonTimeWindow1 = false(nCFU,T);
    for i = 1:nCFU
        pix = find(cfuRegions1{i}>0.1);
        cfuTimeWindow1(i,:) = sum(cfuMapVideo(pix,:)==i>0,1);
        cfuNonTimeWindow1(i,:) = sum(cfuMapVideo(pix,:)>0 & cfuMapVideo(pix,:)~=i,1);
        cfuNonTimeWindow1(i,cfuTimeWindow1(i,:)) = false;
        evtInCFU = CFU_lst1{i};
        x0 = cfuCurves1(i,:);
        x0 = movmean(x0,2);
        for j = 1:numel(evtInCFU)
            label = evtInCFU(j);
            [~,~,~,it] = ind2sub([H,W,L,T],evtLst1{label});
            t0 = min(it);
            t1 = max(it);
            riseT = round(cfu.getRisingTime(x0,t0,t1,cfuTimeWindow1(i,:),thrVec));
            cfuOccurrence1(i,round(riseT)) = true;
        end
    end
    clear cfuMapVideo;
    
    cfuInfo = cell(nCFU,8);
    for i = 1:nCFU
        cfuInfo{i,1} = i;
        cfuInfo{i,2} = CFU_lst1{i};   % Slice
        cfuInfo{i,3} = cfuRegions1{i};
        cfuInfo{i,4} = cfuOccurrence1(i,:);
        cfuInfo{i,5} = cfuCurves1(i,:);
        cfuInfo{i,6} = cfuDFFCurves1(i,:); 
        cfuInfo{i,7} = cfuTimeWindow1(i,:); 
        cfuInfo{i,8} = cfuNonTimeWindow1(i,:); 
    end
    cfuInfo1 = cfuInfo;

    if(~opts.singleChannel)
        alpha = cfuOpts.cfuDetect.overlapThr2;
        minNumEvt = cfuOpts.cfuDetect.minNumEvt2;
        [cfuRegions2,CFU_lst2] = cfu.CFU_minMeasure(cfu_pre2,true(numel(cfu_pre2.evtIhw),1),[],opts.sz,alpha,minNumEvt,false);    
        datOrg2 = res.datOrg2;
        datVec = single(reshape(datOrg2,[],T));
        clear datOrg2;
        cfuCurves2 = zeros(numel(cfuRegions2),T);
        cfuDFFCurves2 = zeros(numel(cfuRegions2),T);
        for i = 1:numel(cfuRegions2)
            weightMap = cfuRegions2{i};
            weightMap = weightMap(:);
            idx = find(weightMap>0);
            cfuCurves2(i,:) = weightMap(idx)'*double(datVec(idx,:))/sum(weightMap);
            cfuDFFCurves2(i,:) = getdFF(cfuCurves2(i,:), opts.movAvgWin, opts.cut);
        end
        evtLst2 = res.evt2;
        % rising time judgement
        thrVec = 0.4:0.1:0.6;
        cfuOccurrence2 = false(numel(CFU_lst2),T);
        cfuMapVideo = zeros(H,W,L,T,'uint16');
        nCFU = numel(cfuRegions2);
        for i = 1:numel(CFU_lst2)
            evtInCFU = CFU_lst2{i};
            for j = 1:numel(evtInCFU)
                label = evtInCFU(j);
                cfuMapVideo(evtLst2{label}) = i;
            end
        end
        cfuMapVideo = reshape(cfuMapVideo,[],T);
        cfuTimeWindow2 = false(nCFU,T);
        cfuNonTimeWindow2 = false(nCFU,T);
        for i = 1:nCFU
            pix = find(cfuRegions2{i}>0.1);
            cfuTimeWindow2(i,:) = sum(cfuMapVideo(pix,:)==i>0,1);
            cfuNonTimeWindow2(i,:) = sum(cfuMapVideo(pix,:)>0 & cfuMapVideo(pix,:)~=i,1);
            cfuNonTimeWindow2(i,cfuTimeWindow2(i,:)) = false;
            evtInCFU = CFU_lst2{i};
            x0 = cfuCurves2(i,:);
            x0 = movmean(x0,2);
            for j = 1:numel(evtInCFU)
                label = evtInCFU(j);
                [~,~,~,it] = ind2sub([H,W,L,T],evtLst2{label});
                t0 = min(it);
                t1 = max(it);
                riseT = round(cfu.getRisingTime(x0,t0,t1,cfuTimeWindow2(i,:),thrVec));
                cfuOccurrence2(i,round(riseT)) = true;
            end
        end
        
        nCFU = numel(cfuRegions2);
        cfuInfo = cell(nCFU,8);
        for i = 1:nCFU
            cfuInfo{i,1} = i;
            cfuInfo{i,2} = CFU_lst2{i};   % Slice
            cfuInfo{i,3} = cfuRegions2{i};
            cfuInfo{i,4} = cfuOccurrence2(i,:);
            cfuInfo{i,5} = cfuCurves2(i,:);
            cfuInfo{i,6} = cfuDFFCurves2(i,:);
            cfuInfo{i,7} = cfuTimeWindow2(i,:);
            cfuInfo{i,8} = cfuNonTimeWindow2(i,:);
        end
        cfuInfo2 = cfuInfo;
    else
        cfuInfo2 = [];
    end
end

function dff = getdFF(x0,window,cut)
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

    sigma1 = max(1e-4,sqrt(mean((x0(2:end)-x0(1:end-1)).^2)/2));
    F0 = F0 - pre.obtainBias(window,cut)*sigma1;
    dff = (x0-F0)./(F0+1e-4);
end