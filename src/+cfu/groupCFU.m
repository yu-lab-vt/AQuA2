function groupCFU(~,~,fCFU,f)
    relation = getappdata(fCFU,'relation');
    if isempty(relation)
        return;
    end
    fh = guidata(fCFU); 
    ff = waitbar(0,'Clustering');
    cfuInfo1 = getappdata(fCFU,'cfuInfo1');
    cfuInfo2 = getappdata(fCFU,'cfuInfo2');
    nCFU = size(cfuInfo1,1)+size(cfuInfo2,1);
    % filter
    thr = str2double(fh.pThr.Value);
    cfuNumThr = str2double(fh.minNumCFU.Value);
    select = relation(:,3)<thr;
    relation = relation(select,:);

    % preprocess
    select = relation(:,4)<0;
    relation(select,[1,2]) = relation(select,[2,1]);
    relation(select,4) = -relation(select,4);

    waitbar(0.1,ff);
    
    % sort
    [~,id] = sort(relation(:,3));
    relation = relation(id,:);
    groupLabels = 1:nCFU;
    % clustering
    for k = 1:size(relation,1)
        id01 = relation(k,1);
        id02 = relation(k,2);
        id1 = cfu.findRootLabel(groupLabels,id01);
        id2 = cfu.findRootLabel(groupLabels,id02);
        groupLabels(id1) = min(id1,id2);
        groupLabels(id2) = min(id1,id2);
    end

    for k = 1:nCFU
        root = cfu.findRootLabel(groupLabels,k);
        groupLabels(k) = root;
    end
    
    waitbar(0.7,ff);

    % sort
    cc = label2idx(groupLabels);
    id = cellfun(@numel,cc)>=cfuNumThr;
    cc = cc(id);
    [~,id] = sort(cellfun(@numel,cc),'descend');
    cc = cc(id);
    
    waitbar(0.8,ff);

    % groupInfo
    visited = false(nCFU,1);
    groupInfo = cell(numel(cc),4);
    delays = nan(nCFU,1);
    addedPvalue = nan(nCFU,1);
    for k = 1:numel(cc)
       groupInfo{k,1} = k;
       labels = cc{k};
       p_values = zeros(numel(labels),1);
       for i = 1:numel(labels)
          curLabel = labels(i) ;
          select = relation(:,1)==curLabel | relation(:,2)==curLabel;
          p_values(i) = mean(relation(select,3));
       end
       [minPValue,id] = min(p_values);
       curLabel = labels(id);
       visited(curLabel) = true;
       addedPvalue(curLabel) = minPValue;
       delays(curLabel) = 0;
       addLst = curLabel;
       while(~isempty(addLst))
           curLabel = addLst(1);
           %
           id =  find(relation(:,1) == curLabel);
           for i = 1:numel(id)
               id2 = relation(id(i),2);
               if(~visited(id2))
                   delays(id2) = relation(id(i),4) + delays(curLabel);
                   addedPvalue(id2) = relation(id(i),3);
                   addLst = [addLst,id2];
                   visited(id2) = true;
               end
           end

           id =  find(relation(:,2) == curLabel);
           for i = 1:numel(id)
               id1 = relation(id(i),1);
               if(~visited(id1))
                   delays(id1) = - relation(id(i),4) + delays(curLabel);
                   addedPvalue(id1) = relation(id(i),3);
                   addLst = [addLst,id1];
                   visited(id1) = true;
               end
           end
           addLst = addLst(2:end);
       end

       groupInfo{k,2} = labels;
       groupInfo{k,3} = delays(labels);
       groupInfo{k,4} = addedPvalue(labels);
    end
    fh.pTool2.Visible = 'on';
    setappdata(fCFU,'groupInfo',groupInfo);
    cfu.updtGrpTable(fCFU,f);
    waitbar(1,ff);
    delete(ff);
end