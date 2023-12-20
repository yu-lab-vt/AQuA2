function CFURun(~,~,f)
    
    fh = guidata(f);
    opts = getappdata(f,'opts');
    
    evtLst1 = getappdata(f, 'evt1');
    cfu_pre1 = getappdata(f,'cfu_pre1');
    
    ff = waitbar(0,'Calculating events distance');
    if(isempty(getappdata(f,'cfu_pre1')) || numel(cfu_pre1.evtIhw)~=numel(evtLst1))
        [cfu_pre1] = cfu.CFU_tmp_function(evtLst1,opts.sz,ff);
        setappdata(f,'cfu_pre1',cfu_pre1);
        
        if(~opts.singleChannel)
            evtLst2 = getappdata(f, 'evt2');
            [cfu_pre2] = cfu.CFU_tmp_function(evtLst2,opts.sz,ff);
            setappdata(f,'cfu_pre2',cfu_pre2);
        end
    else
        
        if(~opts.singleChannel)
            cfu_pre2 = getappdata(f,'cfu_pre2');
        end
    end
    waitbar(1,ff);
    delete(ff);
    
    dlgtitle = 'CFU detection';
    prompt = {'How large spatial overlap will you consider two events belong to the same region (from 0 to 1):',...
        'How many signals of one region have would be considered as true signal (nonnegative number):'};
    
    dims = [1 50];
    definput = {'0.5','3'};
    answer = inputdlg(prompt,dlgtitle,dims,definput);    
    alpha = str2double(answer{1});
    minNumEvt = str2double(answer{2});
    
    ff = waitbar(0,'Calculating cfu info');
    [cfuRegions1,CFU_lst1] = cfu.CFU_minMeasure(cfu_pre1,true(numel(cfu_pre1.evtIhw),1),fh.averPro1,opts.sz,alpha,minNumEvt,1);
    title('CFU in channel 1');
    datOrg1 = getappdata(f, 'datOrg1');
    [H,W,T] = size(datOrg1);
    datVec = reshape(datOrg1,[],T);
    clear datOrg1;
    dF1 = getappdata(f, 'dF1');
    dFVec = reshape(dF1,[],T);
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
    for i = 1:numel(CFU_lst1)
        evtInCFU = CFU_lst1{i};
        x0 = cfuCurves1(i,:);
        x0 = movmean(x0,5);
        for j = 1:numel(evtInCFU)
            label = evtInCFU(j);
            [~,~,it] = ind2sub([H,W,T],evtLst1{label});
            t0 = min(it);
            t1 = max(it);
            riseT = round(cfu.getRisingTime(x0,t0,t1,thrVec));
            cfuOccurrence1(i,round(riseT)) = true;
        end
    end
    
    nCFU = numel(cfuRegions1);
    cfuInfo = cell(nCFU,6);
    for i = 1:nCFU
        cfuInfo{i,1} = i;
        cfuInfo{i,2} = CFU_lst1{i};   % Slice
        cfuInfo{i,3} = cfuRegions1{i};
        cfuInfo{i,4} = cfuOccurrence1(i,:);
        cfuInfo{i,5} = cfuCurves1(i,:);
        cfuInfo{i,6} = cfuDFCurves1(i,:); 
    end
    setappdata(f,'cfuInfo1',cfuInfo);
    
    if(~opts.singleChannel)
        [cfuRegions2,CFU_lst2] = cfu.CFU_minMeasure(cfu_pre2,true(numel(cfu_pre2.evtIhw),1),fh.averPro2,opts.sz,alpha,minNumEvt,1);    
        title('CFU in channel 2');
        datOrg2 = getappdata(f, 'datOrg2');
        datVec = reshape(datOrg2,[],T);
        clear datOrg2;
        dF2 = getappdata(f, 'dF2');
        dFVec = reshape(dF2,[],T);
        clear dF2;
        cfuCurves2 = zeros(numel(cfuRegions2),T);
        cfuDFCurves2 = zeros(numel(cfuRegions2),T);
        for i = 1:numel(cfuRegions2)
            weightMap = cfuRegions2{i};
            weightMap = weightMap(:);
            idx = find(weightMap>0);
            cfuCurves2(i,:) = weightMap(idx)'*double(datVec(idx,:))/sum(weightMap);
            cfuDFCurves2(i,:) = weightMap(idx)'*double(dFVec(idx,:))/sum(weightMap);
        end
        evtLst2 = getappdata(f, 'evt2');
        % rising time judgement
        thrVec = 0.4:0.1:0.6;
        cfuOccurrence2 = false(numel(CFU_lst2),T);
        for i = 1:numel(CFU_lst2)
            evtInCFU = CFU_lst2{i};
            x0 = cfuCurves2(i,:);
            x0 = movmean(x0,5);
            for j = 1:numel(evtInCFU)
                label = evtInCFU(j);
                [~,~,it] = ind2sub([H,W,T],evtLst2{label});
                t0 = min(it);
                t1 = max(it);
                riseT = round(cfu.getRisingTime(x0,t0,t1,thrVec));
                cfuOccurrence2(i,round(riseT)) = true;
            end
        end

        nCFU = numel(cfuRegions2);
        cfuInfo = cell(nCFU,6);
        for i = 1:nCFU
            cfuInfo{i,1} = i;
            cfuInfo{i,2} = CFU_lst2{i};   % Slice
            cfuInfo{i,3} = cfuRegions2{i};
            cfuInfo{i,4} = cfuOccurrence2(i,:);
            cfuInfo{i,5} = cfuCurves2(i,:);
            cfuInfo{i,6} = cfuDFCurves2(i,:); 
        end
        setappdata(f,'cfuInfo2',cfuInfo);
    end
    waitbar(1,ff);
    delete(ff);
end