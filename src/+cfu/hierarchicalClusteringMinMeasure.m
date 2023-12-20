function [groups] = hierarchicalClusteringMinMeasure(linkage,nNode,threshold)
    groupLabels = 1:nNode;    
    %% remove no-use edges
    select = linkage(:,3)<threshold;
    linkage = linkage(select,:);
    %% remove same pair
    select = linkage(:,1)~=linkage(:,2);
    linkage = linkage(select,:);
    pix = sub2ind([nNode,nNode],linkage(:,1),linkage(:,2));
    select = true(size(linkage,1),1);
    for i = 1:numel(select)
        a = linkage(i,1);
        b = linkage(i,2);
        samePair = sub2ind([nNode,nNode],b,a);
        id = find(pix==samePair);
        if(~isempty(id))
           measure1 =  linkage(i,3);
           measure2 =  linkage(id,3);
           if(measure1<=measure2)
               select(samePair) = false;
           else
               select(i) = false;
           end
        end
    end
    linkage = linkage(select,:);
    [~,id] = sort(linkage(:,3));
    linkage = linkage(id,:);

    %% linking
    for k = 1:size(linkage,1)
        id1 = linkage(k,1);
        id2 = linkage(k,2);
        id1 = cfu.findRootLabel(groupLabels,id1);
        id2 = cfu.findRootLabel(groupLabels,id2);
        groupLabels(id1) = min(id1,id2);
        groupLabels(id2) = min(id1,id2);
    end

    %% findSameGroup
    for k = 1:nNode
        root = cfu.findRootLabel(groupLabels,k);
        groupLabels(k) = root;
    end
    
    %% Group and sort
    if(nNode == 0)
       groups = [];
       return;
    end
    groups = label2idx(groupLabels);
    [~,id] = sort(cellfun(@numel,groups),'descend');
    groups = groups(id);
end