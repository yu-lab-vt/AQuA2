function [CFU_region,CFU_lst,weightedIhw,evtIhw,parentIds] = CFU_minMeasure(cfu_pre,select,datPro,sz,thr,minEvt,showResults)

    if(~exist('showResults','var'))
        showResults = false;
    end
    
    linkage = cfu_pre.s_t0;
    linkage(:,3) = 1-linkage(:,3);
    weightedIhw = cfu_pre.weightedIhw;
    evtIhw = cfu_pre.evtIhw;
    
    nNode = numel(select);    
    [CFU_lst] = cfu.hierarchicalClusteringMinMeasure(linkage,nNode,1-thr);
    if(isempty(CFU_lst))
        CFU_region = []; 
        CFU_lst = [];
        parentIds = zeros(0,1);
        return;
    end
    
    id = cellfun(@numel,CFU_lst)>=minEvt;
    candidateParentIds = find(id);
    CFU_lst = CFU_lst(id);
    % Spatial refinement makes the final CFU definition explicit: the
    % retained region is a connected component of its weighted footprint
    % above 0.1, after weak bridges and small satellites are removed.
    [CFU_region,CFU_lst,parentIds] = cfu.refineSpatialCFUs( ...
        CFU_lst,evtIhw,weightedIhw,cfu_pre.maxCounts,sz,minEvt,candidateParentIds);


    if(showResults)
        datPro = double(datPro);
        datPro = datPro - min(datPro(:));
        datPro = datPro/max(datPro(:));
        datPro = cat(3,datPro,datPro,datPro);
        
        ov = datPro*0.5;
        for j = 1:numel(CFU_region)
           seedMap = CFU_region{j};
           x = randi(255,[1,3]);
            while (x(1)>0.8*255 && x(2)>0.8*255 && x(3)>0.8*255) || sum(x)<255
                x = randi(255,[1,3]);
            end
           colorMap = cat(3,seedMap*x(1),seedMap*x(2),seedMap*x(3));
           ov = ov + colorMap/255*1;
        end
        figure('Position',[50,100,450,750]);
        imshow(ov);
    end
end
