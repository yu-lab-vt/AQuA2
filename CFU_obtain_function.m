function [cfuInfo,cfu_pre1] = CFU_obtain_function(res,alpha,minNumEvt,rgT,cfu_pre1,showCFU)
    
    opts = res.opts;
    evtLst1 = res.evt1;
    T = opts.sz(4);
    validTemporal = false(1,T);
    validTemporal(rgT) = true;
    select = true(numel(evtLst1),1);
    % filter
    for i = 1:numel(evtLst1)
        [ih,iw,il,it] = ind2sub(opts.sz,evtLst1{i});
        if sum(validTemporal(unique(it)))==0
            select(i) = false;
        end
    end
    evtLst1 = evtLst1(select);

    if ~exist('cfu_pre1','var') || isempty(cfu_pre1)
        [cfu_pre1] = cfu.CFU_tmp_function(evtLst1,true,opts.sz,[]);
    end
    datPro = squeeze(mean(res.datOrg1,4));
    [cfuRegions1,CFU_lst1] = cfu.CFU_minMeasure(cfu_pre1,true(numel(cfu_pre1.evtIhw),1),datPro,opts.sz,alpha,minNumEvt,showCFU);
    datOrg1 = res.datOrg1;
    [H,W,L,T] = size(datOrg1);
    datVec = reshape(datOrg1,[],T);
    clear datOrg1;
    dF1 = res.dF1;
    dFVec = reshape(dF1,[],T);
    if(isempty(dFVec))
        dFVec = datVec;
    end
    clear dF1;
    cfuCurves1 = zeros(numel(cfuRegions1),T);
    cfuDFCurves1 = zeros(numel(cfuRegions1),T);
    for i = 1:numel(cfuRegions1)
        weightMap = cfuRegions1{i};
        weightMap = weightMap(:);
        idx = find(weightMap>0);
        cfuCurves1(i,:) = weightMap(idx)'*double(datVec(idx,:))/sum(weightMap);
        cfuDFCurves1(i,:) = weightMap(idx)'*double(dFVec(idx,:))/sum(weightMap);
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
        cfuInfo{i,6} = cfuDFCurves1(i,:); 
        cfuInfo{i,7} = cfuTimeWindow1(i,:); 
        cfuInfo{i,8} = cfuNonTimeWindow1(i,:); 
    end
end