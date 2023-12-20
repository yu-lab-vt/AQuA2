function [CFU_region,CFU_lst,weightedIhw,evtIhw] = CFU_minMeasure(cfu_pre,select,datPro,sz,thr,minEvt,showResults)

    if(~exist('showResults','var'))
        showResults = false;
    end
    
    linkage = cfu_pre.s_t0;
    linkage(:,3) = 1-linkage(:,3);
    weightedIhw = cfu_pre.weightedIhw;
    maxCounts = cfu_pre.maxCounts;
    evtIhw = cfu_pre.evtIhw;
    
    H = sz(1);
    W = sz(2);
    L = sz(3);
    T = sz(4);
    nNode = numel(select);    
    [CFU_lst] = cfu.hierarchicalClusteringMinMeasure(linkage,nNode,1-thr);
    if(isempty(CFU_lst))
        CFU_region = []; 
        CFU_lst = [];
        return;
    end
    
    id = cellfun(@numel,CFU_lst)>=minEvt;
    CFU_lst = CFU_lst(id);
    %% calculate CFU region
    CFU_region = cell(numel(CFU_lst),1);
    for i = 1:numel(CFU_lst)
        lst = CFU_lst{i};
        weightMap = zeros(H,W,L,'single');
        for j = 1:numel(lst)
            label = lst(j);
            weightMap(evtIhw{label}) = weightMap(evtIhw{label}) + weightedIhw{label}*maxCounts(label);
        end
        weightMap = weightMap/max(weightMap(:));
        CFU_region{i} = weightMap;
    end


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