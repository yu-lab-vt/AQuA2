function CFURunGui(~,~,fCFU,f)
    
    fh = guidata(fCFU);
    if isfield(fh,'spatialBoundaryButton')
        fh.spatialBoundaryButton.Enable = 'off';
    end
    % A new automatic detection replaces the CFU list, so stale manual
    % ellipses must not keep pointing at obsolete local CFU indices.
    cfu.manualCFU('clear', fCFU, f);
    fh.manualCFUHandles = {};
    fh.manualCFUSelected = [0, 0];
    opts = getappdata(f,'opts');
    evtLst1 = getappdata(f, 'evt1');
    fts1 = getappdata(f, 'fts1'); % [Added] Get features for peak times
    cfu_pre1 = getappdata(fCFU,'cfu_pre1');
    fh.favCFUs = [];
    
    ff = waitbar(0,'Calculating events distance');

    if(isempty(getappdata(fCFU,'cfu_pre1')) || numel(cfu_pre1.evtIhw)~=numel(evtLst1)) || (isfield(fh,'preSpa') && fh.preSpa~=fh.spatialOption.Value)
        [cfu_pre1] = cfu.CFU_tmp_function(evtLst1,fh.spatialOption.Value,opts.sz,ff);
        setappdata(fCFU,'cfu_pre1',cfu_pre1);
        
        if(~opts.singleChannel)
            evtLst2 = getappdata(f, 'evt2');
            [cfu_pre2] = cfu.CFU_tmp_function(evtLst2,fh.spatialOption.Value,opts.sz,ff);
            setappdata(fCFU,'cfu_pre2',cfu_pre2);
        end
        fh.preSpa = fh.spatialOption.Value;
    else
        
        if(~opts.singleChannel)
            cfu_pre2 = getappdata(fCFU,'cfu_pre2');
        end
    end
    waitbar(1,ff);
    delete(ff);
    
    alpha = str2double(fh.alpha.Value);
    minNumEvt = str2double(fh.minNumEvt.Value);

    % Developer Ver 2025/03/06: Set time window for valid events for CFU
    tStart = 1;           % Set Start Frame
    tEnd = opts.sz(4);    % End Frame
    
    if isfield(fts1, 'curve') && isfield(fts1.curve, 'dffMaxFrame')
        peakFrames = fts1.curve.dffMaxFrame;
        validEvts1 = (peakFrames >= tStart) & (peakFrames <= tEnd);
        validEvts1 = validEvts1(:);
    else
        validEvts1 = true(numel(cfu_pre1.evtIhw),1);
        warning('Peak frame features not found, using all events.');
    end

    ff = waitbar(0,'Calculating cfu info');
    [cfuRegions1,CFU_lst1,~,~,cfuParentIds1,cfuMemberships1] = cfu.CFU_minMeasure(cfu_pre1,validEvts1,fh.averPro1,opts.sz,alpha,minNumEvt,false);
    cfuMemberships1 = cfu.materializeCFUMemberships(cfuMemberships1,evtLst1,opts.sz);
    % End Developer Ver 2025/03/06

    waitbar(0.3,ff);
    title('CFU in channel 1');
    datOrg1 = getappdata(f, 'datOrg1');
    [H,W,L,T] = size(datOrg1);
    datVec = reshape(datOrg1,[],T);
    datVec = datVec*(opts.maxValueDat1 - opts.minValueDat1) + opts.minValueDat1;
    clear datOrg1;
    [cfuCurves1, cfuDFFCurves1] = cfu.computeCFUCurves( ...
        cfuRegions1, datVec, opts.movAvgWin, opts.cut);
    mergeParameters = cfu.defaultCFUMergeParameters();
    mergeParameters.ProgressCallback = @(stage,roundIndex,maxRounds,count) ...
        updateMergeWaitbar(ff, 1, stage, roundIndex, maxRounds, count);
    [cfuRegions1, CFU_lst1, cfuParentIds1, cfuMemberships1, cfuCurves1, ...
        cfuDFFCurves1, ~, ~, mergeDiagnostics1] = cfu.iterativeMergeSimilarCFUs(cfuRegions1, ...
        CFU_lst1, cfuParentIds1, cfuMemberships1, cfuCurves1, ...
        cfuDFFCurves1, datVec, opts.movAvgWin, opts.cut, mergeParameters);
    waitbar(0.6,ff);
    
    % rising time judgement
    thrVec = 0.4:0.1:0.6;
    cfuOccurrence1 = false(numel(CFU_lst1),T);
    nCFU = numel(cfuRegions1);
    [cfuTimeWindow1, cfuNonTimeWindow1, overlappingCFUs1] = ...
        cfu.membershipTimeWindows(cfuMemberships1, cfuRegions1, opts.sz);
    waitbar(0.9,ff);
    
    cfuInfo = cell(nCFU,14);
    
    for i = 1:nCFU
        pix = find(cfuRegions1{i}>0.1);
        evtInCFU = CFU_lst1{i};
        x0 = cfuCurves1(i,:);
        x0 = movmean(x0,2);
        
        tPeaks = zeros(numel(evtInCFU), 1); 
        ownTimeFrames = cell(numel(evtInCFU), 1);
        
        for j = 1:numel(evtInCFU)
            label = evtInCFU(j);
            [ih_ev, iw_ev, il_ev, it_ev] = ind2sub([H,W,L,T],evtLst1{label});
            t0 = min(it_ev);
            t1 = max(it_ev);
            % 提取仅仅落入当前 CFU 空间范围内的活跃时间帧
            spa_ev = sub2ind([H,W,L], ih_ev, iw_ev, il_ev);
            ownTimeFrames{j} = unique(it_ev(ismember(spa_ev, pix)));
            
            tPeaks(j) = fts1.curve.dffMaxFrame(label); % Use peak frame
            
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
        cfuInfo{i,9} = calcFreqStats(tPeaks, opts.frameRate); 
        
        % Calculate uncertain events
        % --- 第10列：使用“精确逐帧 IoU”筛选灰色事件（包含自身筛查与内部去重） ---
        iouThr = 0.5; % 逐帧重叠率 > 50% 即判定为同一生理活动的碎片
        iouThr2 = 0.1;
        overlappingCFUs = overlappingCFUs1{i};
        
        initialGrayEvts = [];
        grayTimeFramesCell = {}; % 缓存灰色事件的精确活跃帧，用于后续内部两两比较
        
        for oCfuIdx = overlappingCFUs(:)'
            evtsInOther = setdiff(cfuMemberships1{oCfuIdx}.EventID, ...
                cfuMemberships1{i}.EventID, 'stable');
            for eIdx = 1:numel(evtsInOther)
                evID = evtsInOther(eIdx);
                
                % 1. 快速空间交集初筛
                if ~isempty(intersect(cfu_pre1.evtIhw{evID}, pix))
                    
                    % 2. 提取该灰色事件在当前区域内的确切活跃时间帧
                    [ih_gray, iw_gray, il_gray, it_gray] = ind2sub([H,W,L,T],evtLst1{evID});
                    spa_gray = sub2ind([H,W,L], ih_gray, iw_gray, il_gray);
                    grayTimeFrames = unique(it_gray(ismember(spa_gray, pix)));
                    
                    % 防止异常空帧
                    if isempty(grayTimeFrames)
                        continue;
                    end

                    % 如果该灰色事件在当前区域的活跃时刻，有 >50% 落在了 CFU 的整体时间窗内
                    overlapGlobalCnt = sum(cfuTimeWindow1(i, grayTimeFrames));
                    if (overlapGlobalCnt / numel(grayTimeFrames)) > 0.5
                        continue; % 判定为被 CFU 整体活动掩盖的无效事件，直接排除
                    end
                    
                    % 3. 检查与当前 CFU 自身事件的重复率
                    isDuplicate = false;
                    for k = 1:numel(ownTimeFrames)
                        own_t = ownTimeFrames{k};
                        if isempty(own_t)
                            continue;
                        end
                        
                        % 基于精确帧计算 IoU
                        inter_len = numel(intersect(own_t, grayTimeFrames));
                        union_len = numel(union(own_t, grayTimeFrames));
                        iou = inter_len / union_len;
                        
                        if iou > iouThr
                            isDuplicate = true;
                            break; 
                        end
                    end
                    
                    if ~isDuplicate
                        initialGrayEvts(end+1) = evID;
                        grayTimeFramesCell{end+1} = grayTimeFrames;
                    end
                end
            end
        end
        
        % 4. 灰色事件内部的两两 IoU 筛查去重
        nGray = numel(initialGrayEvts);
        keepIdx = true(nGray, 1); % 标记位，标记为 true 的最终保留
        
        for m = 1:nGray
            if ~keepIdx(m)
                continue; % 已经被判定为重复而舍弃的，不再作为基准
            end
            frames_m = grayTimeFramesCell{m};
            
            for n = (m+1):nGray
                if ~keepIdx(n)
                    continue;
                end
                frames_n = grayTimeFramesCell{n};
                
                inter_len = numel(intersect(frames_m, frames_n));
                union_len = numel(union(frames_m, frames_n));
                iou = inter_len / union_len;
                
                if iou > iouThr2
                    % 发现高度重合，判定为代表了同一个峰，保留 m，剔除 n
                    keepIdx(n) = false;
                end
            end
        end
        
        finalGrayEvts = initialGrayEvts(keepIdx);
        cfuInfo{i,10} = finalGrayEvts;
        cfuInfo{i,13} = cfuParentIds1(i); % original hierarchy cluster ID
        cfuInfo{i,14} = cfuMemberships1{i}; % shared-event local masks and scores
    end
    setappdata(fCFU,'cfuInfo1',cfuInfo);
    setappdata(fCFU,'cfuMergeDiagnostics1',mergeDiagnostics1);
    
    % cfuMap
    cfuMap1 = zeros(H,W,L,'uint16');
    for i = 1:nCFU
       cfuMap1(cfuRegions1{i}>0.1) = i;
    end
    fh.cfuMap1 = cfuMap1;

    dsSclXY = fh.sldDsXY.Value;
    Data = se.myResize(zeros(opts.sz(1:3),'single'),1/dsSclXY);
    overlayLabelDs = zeros(size(Data),'uint16');
    cfuShow = label2idx(fh.cfuMap1);
    for i = 1:numel(cfuShow)
        if ~isempty(cfuShow{i})
            [ih,iw,il] = ind2sub([opts.sz(1:3)],cfuShow{i});
            pix0 = unique(sub2ind(size(Data),ceil(ih/dsSclXY),ceil(iw/dsSclXY),il));
            overlayLabelDs(pix0) = i;
        end
    end
    fh.cfuMapDS1 = overlayLabelDs;
    
    %%
    if(~opts.singleChannel)
        fts2 = getappdata(f, 'fts2'); 
        evtLst2 = getappdata(f, 'evt2');
        alpha = str2double(fh.alpha2.Value);
        minNumEvt = str2double(fh.minNumEvt2.Value);
        [cfuRegions2,CFU_lst2,~,~,cfuParentIds2,cfuMemberships2] = cfu.CFU_minMeasure(cfu_pre2,true(numel(cfu_pre2.evtIhw),1),fh.averPro2,opts.sz,alpha,minNumEvt,false);
        cfuMemberships2 = cfu.materializeCFUMemberships(cfuMemberships2,evtLst2,opts.sz);
        waitbar(0.3,ff);
        title('CFU in channel 2');
        datOrg2 = getappdata(f, 'datOrg2');
        datVec = reshape(datOrg2,[],T);
        datVec = datVec*(opts.maxValueDat2 - opts.minValueDat2) + opts.minValueDat2;
        clear datOrg2;
        [cfuCurves2, cfuDFFCurves2] = cfu.computeCFUCurves( ...
            cfuRegions2, datVec, opts.movAvgWin, opts.cut);
        mergeParameters = cfu.defaultCFUMergeParameters();
        mergeParameters.ProgressCallback = @(stage,roundIndex,maxRounds,count) ...
            updateMergeWaitbar(ff, 2, stage, roundIndex, maxRounds, count);
        [cfuRegions2, CFU_lst2, cfuParentIds2, cfuMemberships2, cfuCurves2, ...
            cfuDFFCurves2, ~, ~, mergeDiagnostics2] = cfu.iterativeMergeSimilarCFUs(cfuRegions2, ...
            CFU_lst2, cfuParentIds2, cfuMemberships2, cfuCurves2, ...
            cfuDFFCurves2, datVec, opts.movAvgWin, opts.cut, mergeParameters);
        waitbar(0.6,ff);
        % rising time judgement
        thrVec = 0.4:0.1:0.6;
        cfuOccurrence2 = false(numel(CFU_lst2),T);
        nCFU = numel(cfuRegions2);
        [cfuTimeWindow2, cfuNonTimeWindow2] = ...
            cfu.membershipTimeWindows(cfuMemberships2, cfuRegions2, opts.sz);
        waitbar(0.9,ff);
        
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
                
                tPeaks(j) = fts2.curve.dffMaxFrame(label); 
                
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
            cfuInfo{i,9} = calcFreqStats(tPeaks, opts.frameRate);   % 2025/12/04 updated
            cfuInfo{i,13} = cfuParentIds2(i); % original hierarchy cluster ID
            cfuInfo{i,14} = cfuMemberships2{i}; % shared-event local masks and scores
        end
        setappdata(fCFU,'cfuInfo2',cfuInfo);
        setappdata(fCFU,'cfuMergeDiagnostics2',mergeDiagnostics2);
        
        cfuMap2 = zeros(H,W,L,'uint16');
        for i = 1:nCFU
           cfuMap2(cfuRegions2{i}>0.1) = i;
        end
        fh.cfuMap2 = cfuMap2;

        dsSclXY = fh.sldDsXY.Value;
        Data = se.myResize(zeros(opts.sz(1:3),'single'),1/dsSclXY);
        overlayLabelDs = zeros(size(Data),'uint16');
        cfuShow = label2idx(fh.cfuMap2);
        for i = 1:numel(cfuShow)
            if ~isempty(cfuShow{i})
                [ih,iw,il] = ind2sub([opts.sz(1:3)],cfuShow{i});
                pix0 = unique(sub2ind(size(Data),ceil(ih/dsSclXY),ceil(iw/dsSclXY),il));
                overlayLabelDs(pix0) = i;
            end
        end
        fh.cfuMapDS2 = overlayLabelDs;
    end
    waitbar(1,ff);
    
    fh.pickButton.Enable = 'on';
    fh.viewButton.Enable = 'on';
    fh.addAllButton.Enable = 'on';
    fh.calDep.Enable = 'on';
    fh.selectCFUs = [];
    fh.pThr.Enable = 'off';
    fh.minNumCFU.Enable = 'off';
    fh.buttonGroup.Enable = 'off';
    fh.winSz.Enable = 'on';
    fh.sldWinSz.Enable = 'on';
    fh.shift.Enable = 'on';
    cfu.applySpatialBoundary(fCFU);
    if isfield(fh,'spatialBoundaryButton')
        fh.spatialBoundaryButton.Enable = 'on';
    end
%     fh.pThr.Enable = 'on';
%     fh.minNumCFU.Enable = 'on';
%     fh.buttonGroup.Enable = 'on';
    fh.groupShow = 0;
    guidata(fCFU,fh);
    
    try
        rmappdata(fCFU,'relation');
        rmappdata(fCFU,'groupInfo');
    end
    fh.pTool1.Visible = 'on';
    fh.pTool2.Visible = 'on';
    guidata(fCFU,fh);
    cfu.manualCFU('enable', fCFU, f);
    cfu.updtCFUTable(fCFU);     % 08/27/2025 updated: clear table after rerun
    cfu.updtGrpTable(fCFU,f);
    ui.updtCFUint([],[],fCFU,true);
    
    delete(ff);
end

function updateMergeWaitbar(waitbarHandle, channelIndex, stage, roundIndex, maxRounds, count)
    if ~isgraphics(waitbarHandle)
        return;
    end
    progressBase = 0.32;
    progressSpan = 0.24;
    if strcmp(stage, 'evaluate')
        progress = progressBase + progressSpan * (roundIndex - 1) / maxRounds;
        message = sprintf('CFU channel %d: merge round %d/%d, evaluating candidates', ...
            channelIndex, roundIndex, maxRounds);
    else
        progress = progressBase + progressSpan * (roundIndex - 0.5) / maxRounds;
        message = sprintf('CFU channel %d: merge round %d/%d, updating %d CFUs', ...
            channelIndex, roundIndex, maxRounds, count);
    end
    waitbar(min(progress, 0.58), waitbarHandle, message);
    drawnow limitrate;
end

% Helper function
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
        dt_vals = dt;

        if ~isempty(dt)
            cv = std(dt) / mean(dt);

            if cv > 1.0
                mainFreq = median(1 ./ dt);
                methodStr = 'Med';
            else
                mainFreq = 1 / mean(dt);
                methodStr = 'Mean';
            end

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
