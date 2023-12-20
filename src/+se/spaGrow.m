function [majorityEvt0,Map] = spaGrow(Map,activeMap,dF,opts)
% ----------- Modified by Xuelong Mi, 11/10/2022 -----------
    sdLst = label2idx(Map);
    [H,W,T] = size(dF);
    nEvt = numel(sdLst);
    dF = reshape(dF,[],T);
    Map = reshape(Map,[],T);
    activeMap = reshape(activeMap,[],T);
    tmp = cell(nEvt,1);
    corSigThr = 1e-3;
%     tic;
    for i = 1:nEvt
        [ih,iw,it] = ind2sub([H,W,T],sdLst{i});
        curIhw = unique(sub2ind([H,W],ih,iw));
        refCurve = mean(dF(curIhw,:),1);
        t0 = min(it); t1 = max(it);
        % update reference time course
        [peakV,tPeak] = max(refCurve(t0:t1));
        tPeak = tPeak + t0 - 1;
        [~,tMin] = min(refCurve(t0:tPeak)); t0 = t0 + tMin - 1;
        [~,tMin] = min(refCurve(tPeak:t1)); t1 = tMin + tPeak - 1;
        % find timewindow of the peak
        if opts.noiseEstimation~=3
            % using noise
            sigma = sqrt(median((refCurve(2:end)-refCurve(1:end-1)).^2)/0.9133);
            thr = 3*sigma;
        else
            % no noise
            thr = 0.1 * peakV;
        end

        vMin = refCurve(t0); t = t0;
        while t>=1
            if refCurve(t)-vMin>thr
                break;
            end
            if refCurve(t)<thr
                t0 = t;
                break;
            else
                if refCurve(t)<vMin
                    vMin = refCurve(t); t0 = t;
                end
                t = t - 1;
            end
        end
        vMin = refCurve(t1); t = t1;
        while t<=T
            if refCurve(t)-vMin>thr
                break;
            end
            if refCurve(t)<thr
                t1 = t;
                break;
            else
                if refCurve(t)<vMin
                    vMin = refCurve(t); t1 = t;
                end
                t = t + 1;
            end
        end
        t05 = find(refCurve(t0:tPeak)>0.5*(peakV+refCurve(t0)),1) + t0 - 1;
        t15 = find(refCurve(tPeak:t1)>0.5*(peakV+refCurve(t1)),1,'last') + tPeak - 1;

        n = min(40,t1-t0+1);
        zscoreThr = -tinv(corSigThr,n-2);
        score = (zscoreThr/sqrt(n-2))^2;
        tmp{i}.rThr = min(0.7,sqrt(score/(score+1)));

        tmp{i}.TW = [t0,t1];
        tmp{i}.TW55 = [t05,t15];
        tmp{i}.curve = refCurve(t0:t1);
        tmp{i}.newAdd = curIhw;
        tmp{i}.checked = curIhw;
        tmp{i}.added = true(numel(curIhw),1);
        tmp{i}.delays = zeros(numel(curIhw),1);
        tmp{i}.newDelays = zeros(numel(curIhw),1);
        tmp{i}.newDists = zeros(numel(curIhw),1);
        tmp{i}.tPeak = tPeak;
    end
%     toc;

    dh = [-1,-1,-1,0,0,1,1,1];
    dw = [-1,0,1,-1,1,-1,0,1];

    delayMap = nan(H,W);
    distMap = nan(H,W);
%     tic;
    for k = 1:100    % grow 40 rounds
        disp(['Grow ',num2str(k),' Round']);
        for i = 1:nEvt
            if isempty(tmp{i}.newAdd)   % no neighbor pixels could be added.
                continue;
            end
            newDists = tmp{i}.newDists;
            curPix = tmp{i}.newAdd;
            shifts = unique(tmp{i}.newDelays);

            candidateIn = [];
            candidateOut = [];
            maxCor = -ones(H,W);
            t0 = tmp{i}.TW(1);
            t1 = tmp{i}.TW(2);
            t05 = tmp{i}.TW55(1);
            t15 = tmp{i}.TW55(2);
            L = t1-t0+1;
            refCurve = tmp{i}.curve;
            
            % grow the pixels according to shifts. Grow the pixels in
            % batches.
            for ii = 1:numel(shifts)
                shift = shifts(ii);
                select = tmp{i}.newDelays==shift;
                [ih,iw] = ind2sub([H,W],curPix(select));
                curDists = newDists(select);
                curNei = [];
                for kk = 1:numel(dh)
                    ih0 = min(max(1,ih + dh(kk)),H);
                    iw0 = min(max(1,iw + dw(kk)),W);
                    nei = sub2ind([H,W],ih0,iw0);
                    distMap(nei) = curDists + 1;   % update distance
                    curNei = [curNei;nei];
                end
                curNei = setdiff(curNei,tmp{i}.checked);
                select = activeMap(curNei,tmp{i}.tPeak + shift);
                outAct = curNei(~select);   % out of active region
                curNei = curNei(select);    % in active region
                distMap(curNei) = 0;
                
                outAct = outAct(distMap(outAct)<2*opts.spaMergeDist + 1);   % distance
                delayMap(outAct) = shift;
                
                candidateIn = [candidateIn;curNei];
                candidateOut = [candidateOut;outAct];

                tStart = t0 + shift + [-1:1];
                tStart = tStart(tStart>0 & tStart<=T+1-L);
                for j = 1:numel(tStart)
                    alignCurves = dF(curNei,tStart(j):tStart(j)+L-1);
                    r = corr(refCurve',alignCurves')';
                    select = r>maxCor(curNei);
                    selectPix = curNei(select);
                    maxCor(selectPix) = r(select);
                    delayMap(selectPix) = tStart(j)-t0;
                end
            end
            
            % correlation similarity
            % in active region
            candidateIn = unique(candidateIn);
            select = maxCor(candidateIn)>tmp{i}.rThr;
            newAdd = candidateIn(select);
%             newLose = candidateIn(~select);
            newDelays = delayMap(newAdd);
            newAddVox = sub2ind([H*W,T],newAdd,tmp{i}.tPeak + newDelays);
            select = Map(newAddVox)==0; % not added in other group
            newAdd = newAdd(select);
            newDelays = newDelays(select);

            % label new pixels
            for t = t05:t15
                newAddVox = sub2ind([H*W,T],newAdd,t + newDelays);
                Map(newAddVox(Map(newAddVox)==0)) = i;
            end

            % out of active region
            candidateOut = setdiff([candidateOut],newAdd);
            
            % update
            tmp{i}.newAdd = [newAdd;candidateOut];
            tmp{i}.newDelays = [newDelays;delayMap(candidateOut)];
            tmp{i}.newDists = distMap(tmp{i}.newAdd);

            tmp{i}.checked = [tmp{i}.checked;candidateIn;candidateOut];
            tmp{i}.delays = [tmp{i}.delays;tmp{i}.newDelays];
            tmp{i}.added = [tmp{i}.added;true(numel(newAdd),1);false(numel(candidateOut),1)];
        end
    end

    % majority and output
    majorityEvt0 = cell(nEvt,1);
    Map = reshape(Map,[H,W,T]);
    for i = 1:nEvt
        majorityEvt0{i}.ihw = tmp{i}.checked(tmp{i}.added);
        majorityEvt0{i}.TW = tmp{i}.TW(1):tmp{i}.TW(2);
        majorityEvt0{i}.delays = tmp{i}.delays(tmp{i}.added);
        majorityEvt0{i}.needUpdatePeak = true;
        majorityEvt0{i}.curve = tmp{i}.curve; 
    end
%     toc;
end