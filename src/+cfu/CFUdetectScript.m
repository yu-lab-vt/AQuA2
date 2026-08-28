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
    [cfuRegions1,CFU_lst1,~,~,cfuParentIds1,cfuMemberships1] = cfu.CFU_minMeasure(cfu_pre1,true(numel(cfu_pre1.evtIhw),1),[],opts.sz,alpha,minNumEvt,false);
    cfuMemberships1 = cfu.materializeCFUMemberships(cfuMemberships1,evtLst1,opts.sz);
    datOrg1 = res.datOrg1;
    [H,W,L,T] = size(datOrg1);
    datVec = single(reshape(datOrg1,[],T));
    clear datOrg1;
    [cfuCurves1, cfuDFFCurves1] = cfu.computeCFUCurves( ...
        cfuRegions1, datVec, opts.movAvgWin, opts.cut);
    mergeParameters = cfu.defaultCFUMergeParameters();
    [cfuRegions1, CFU_lst1, cfuParentIds1, cfuMemberships1, didMerge1] = ...
        cfu.mergeSimilarCFUs(cfuRegions1, CFU_lst1, cfuParentIds1, ...
        cfuMemberships1, cfuDFFCurves1, mergeParameters);
    if didMerge1
        [cfuCurves1, cfuDFFCurves1] = cfu.computeCFUCurves( ...
            cfuRegions1, datVec, opts.movAvgWin, opts.cut);
    end

    % rising time judgement
    thrVec = 0.4:0.1:0.6;
    cfuOccurrence1 = false(numel(CFU_lst1),T);
    nCFU = numel(cfuRegions1);
    [cfuTimeWindow1, cfuNonTimeWindow1] = ...
        cfu.membershipTimeWindows(cfuMemberships1, cfuRegions1, opts.sz);
    
    cfuInfo = cell(nCFU,14);
    
    for i = 1:nCFU
        evtInCFU = CFU_lst1{i};
        x0 = cfuCurves1(i,:);
        x0 = movmean(x0,2);
        
        tPeaks = zeros(numel(evtInCFU), 1);
        
        for j = 1:numel(evtInCFU)
            label = evtInCFU(j);
            [~,~,~,it] = ind2sub([H,W,L,T],evtLst1{label});
            t0 = min(it);
            t1 = max(it);
            
            tPeaks(j) = res.fts1.curve.dffMaxFrame(label);
            
            riseT = round(cfu.getRisingTime(x0,t0,t1,cfuTimeWindow1(i,:),thrVec));
            cfuOccurrence1(i,round(riseT)) = true;
        end
        
        cfuInfo{i,1} = i;
        cfuInfo{i,2} = CFU_lst1{i};   % Slice
        cfuInfo{i,3} = cfuRegions1{i};
        cfuInfo{i,4} = cfuOccurrence1(i,:);
        cfuInfo{i,5} = cfuCurves1(i,:);
        cfuInfo{i,6} = cfuDFFCurves1(i,:); 
        cfuInfo{i,7} = cfuTimeWindow1(i,:); 
        cfuInfo{i,8} = cfuNonTimeWindow1(i,:); 
        cfuInfo{i,9} = calcFreqStats(tPeaks, opts.frameRate);   % 2025/12/04 updated
        cfuInfo{i,13} = cfuParentIds1(i); % original hierarchy cluster ID
        cfuInfo{i,14} = cfuMemberships1{i}; % shared-event local masks and scores
    end
    cfuInfo1 = cfuInfo;

    if(~opts.singleChannel)
        alpha = cfuOpts.cfuDetect.overlapThr2;
        minNumEvt = cfuOpts.cfuDetect.minNumEvt2;
        [cfuRegions2,CFU_lst2,~,~,cfuParentIds2,cfuMemberships2] = cfu.CFU_minMeasure(cfu_pre2,true(numel(cfu_pre2.evtIhw),1),[],opts.sz,alpha,minNumEvt,false);
        cfuMemberships2 = cfu.materializeCFUMemberships(cfuMemberships2,evtLst2,opts.sz);
        datOrg2 = res.datOrg2;
        datVec = single(reshape(datOrg2,[],T));
        clear datOrg2;
        [cfuCurves2, cfuDFFCurves2] = cfu.computeCFUCurves( ...
            cfuRegions2, datVec, opts.movAvgWin, opts.cut);
        mergeParameters = cfu.defaultCFUMergeParameters();
        [cfuRegions2, CFU_lst2, cfuParentIds2, cfuMemberships2, didMerge2] = ...
            cfu.mergeSimilarCFUs(cfuRegions2, CFU_lst2, cfuParentIds2, ...
            cfuMemberships2, cfuDFFCurves2, mergeParameters);
        if didMerge2
            [cfuCurves2, cfuDFFCurves2] = cfu.computeCFUCurves( ...
                cfuRegions2, datVec, opts.movAvgWin, opts.cut);
        end
        evtLst2 = res.evt2;
        % rising time judgement
        thrVec = 0.4:0.1:0.6;
        cfuOccurrence2 = false(numel(CFU_lst2),T);
        nCFU = numel(cfuRegions2);
        [cfuTimeWindow2, cfuNonTimeWindow2] = ...
            cfu.membershipTimeWindows(cfuMemberships2, cfuRegions2, opts.sz);
        
        cfuInfo = cell(nCFU,14);
        
        for i = 1:nCFU
            evtInCFU = CFU_lst2{i};
            x0 = cfuCurves2(i,:);
            x0 = movmean(x0,2);
            
            tPeaks = zeros(numel(evtInCFU), 1);
            
            for j = 1:numel(evtInCFU)
                label = evtInCFU(j);
                [~,~,~,it] = ind2sub([H,W,L,T],evtLst2{label});
                t0 = min(it);
                t1 = max(it);
                
                tPeaks(j) = res.fts2.curve.dffMaxFrame(label);
                
                riseT = round(cfu.getRisingTime(x0,t0,t1,cfuTimeWindow2(i,:),thrVec));
                cfuOccurrence2(i,round(riseT)) = true;
            end
            
            cfuInfo{i,1} = i;
            cfuInfo{i,2} = CFU_lst2{i};   % Slice
            cfuInfo{i,3} = cfuRegions2{i};
            cfuInfo{i,4} = cfuOccurrence2(i,:);
            cfuInfo{i,5} = cfuCurves2(i,:);
            cfuInfo{i,6} = cfuDFFCurves2(i,:);
            cfuInfo{i,7} = cfuTimeWindow2(i,:);
            cfuInfo{i,8} = cfuNonTimeWindow2(i,:);
            cfuInfo{i,9} = calcFreqStats(tPeaks, opts.frameRate);
            cfuInfo{i,13} = cfuParentIds2(i); % original hierarchy cluster ID
            cfuInfo{i,14} = cfuMemberships2{i}; % shared-event local masks and scores
        end
        cfuInfo2 = cfuInfo;
    else
        cfuInfo2 = [];
    end
end

function stats = calcFreqStats(tPeaks, s_per_frame)
    
    cnt = length(tPeaks);
    dt_vals = [];
    mainFreq = 0;
    methodStr = 'N/A';
    peakFreq80 = NaN;

    if cnt >= 2
        tPeaks = sort(tPeaks);
        dt = diff(tPeaks) * s_per_frame;
        
        dt = dt(dt > 0); 
        dt_vals = dt; % Store for debug/export if needed

        if ~isempty(dt)

            cv = std(dt) / mean(dt);

            % 2. Dynamic Selection Logic
            if cv > 1.0
                % High dispersion (bursty) -> Use Median
                mainFreq = median(1 ./ dt);
                methodStr = 'Med';
            else
                % Regular distribution or small N -> Use Mean
                mainFreq = 1 / mean(dt);
                methodStr = 'Mean';
            end

            % 3. Peak Frequency (80th Percentile, only if N >= 5)
            % Matches "if length(dt) >= 5" in reference
            if length(dt) >= 5
                peakFreq80 = prctile(1 ./ dt, 80);
            end
        end
    end
    
    stats = struct('count', cnt, ...
                   'mainFreq', mainFreq, ...
                   'method', methodStr, ...
                   'peakFreq80', peakFreq80, ...
                   'dt', dt_vals);
end
