function [evtLst,sdLst,curRegions] = segmentation_MSF2(Map,curRegions,dF,dFOrg,opts,ff)
% ----------- Modified by Xuelong Mi, 02/20/2023 -----------
    conn = 26;
    penalty = 0;
    [H,W,T] = size(dF);
    opts.spaSmo = 3;                % default paramter for watershed
    growMap = zeros(H,W,T,'uint16');
%     tic;
    for i = 1:numel(curRegions)
        growMap(curRegions{i}) = i;
    end
    if opts.spaMergeDist>0
        growMap = imdilate(growMap,strel('disk',opts.spaMergeDist));
    end
    growList = label2idx(growMap);
%     toc;
    clear growMap;
    if conn==26
        dw = [0,0,0, 0,1,1,1,1, 1, 1, 1, 1, 1];
        dh = [1,0,1,-1,0,1,0,1,-1, 0,-1,-1, 1];
        dt = [0,1,1, 1,0,0,1,1, 0,-1,-1, 1,-1];
    else
        dw = [1,0,0];
        dh = [0,1,0];
        dt = [0,0,1];
    end
    
    sdLst = label2idx(Map);
    scoreMap = -imgaussfilt(dF,opts.spaSmo); % spatial smoothing to weaken gap in spatial

%     gaussFactor = 0;
%     h0 = zeros(1,gaussFactor*2+1);
%     h0(gaussFactor+1) = 1;
%     h0 = imgaussfilt(h0,1);
%     
%     h = zeros(1,1,gaussFactor*2+3);
%     h(1,1,:) = conv(h0,[1,-2,1]);
%     pcMap = imfilter(dF,h);
%     % scoreMap = scoreMap + pcMap/sqrt(sum(h.^2));

    clear dF;
    dFVec = reshape(dFOrg,[],T);
    clear dFOrg;

    % calculate scoreMap
    Ttestopen = true;
    nEvt = max(Map(:));
    gap = 1;
    seedsInRegion = cell(numel(curRegions),1);

    % check whether the whole active region is significant or not
    validRegion = false(numel(curRegions),1);
    for i = 1:numel(curRegions)
         pix = curRegions{i};
%          [ih,iw,it] = ind2sub([H,W,T],pix);
%          ihw = unique(sub2ind([H,W],ih,iw));
%          dur = max(it)-min(it)+1;
         labels = setdiff(Map(pix),0);
         
         if(isempty(labels))    % no seed

         elseif(numel(labels) == 1)
            Map(pix) = labels(1);
         end
         seedsInRegion{i} = labels;
         validRegion(i) = ~isempty(labels);
    end

    mapping = zeros(H,W,T);
    seedWeight = -10000;
    % watershed
     for i = 1:numel(curRegions)
        if exist('ff','var')&&~isempty(ff)
            waitbar(0.4 + 0.3*i/numel(curRegions),ff);
        end
        labels = seedsInRegion{i};
        if(numel(labels)>1)
            actPix = curRegions{i};
            pix = growList{i};
            [ih,iw,it] = ind2sub([H,W,T],pix);

            % simplify
            mapping(pix) = 1:numel(pix);

            % Multiple seeds, need to split 
            edges = zeros(numel(dh)*numel(pix),3);
            cnt = 0;
            for k = 1:numel(dh)
                pix0 = sub2ind([H,W,T],max(1,min(ih+dh(k),H)),max(1,min(iw+dw(k),W)),max(1,min(it+dt(k),T)));
                select = pix0~=pix & ismember(pix0,pix);
                id1 = mapping(pix(select));
                id2 = mapping(pix0(select));
                ee = [id1,id2,scoreMap(pix(select)) + scoreMap(pix0(select))/2];
                if dt(k)~=0
                    ee(:,3) = ee(:,3) + penalty;
                end
                edges(cnt+1:cnt+size(ee,1),:) = ee;
                cnt = cnt + size(ee,1);
            end
            edges = edges(1:cnt,:);

            % Seed, imaginary root
            cnt = 0;
            for ii = 1:numel(labels)
                cnt = cnt + numel(sdLst{labels(ii)});
            end
            seedEdges = zeros(cnt,3);
            cnt = 0;
            rootID = numel(pix) + 1;
%             rootEdges = [];
            % seed edges
            for ii = 1:numel(labels)
                seed = sdLst{labels(ii)};
                [ih,iw,it] = ind2sub([H,W,T],seed);
                for k = 1:numel(dw)
                    seed0 = sub2ind([H,W,T],max(1,min(ih+dh(k),H)),max(1,min(iw+dw(k),W)),max(1,min(it+dt(k),T)));
                    select = ismember(seed0,seed) & seed0~=seed;
                    id1 = mapping(seed(select));
                    id2 = mapping(seed0(select));
                    curEdges = [id1,id2,ones(sum(select),1)*seedWeight];
                    seedEdges(cnt+1:cnt+size(curEdges,1),:) = curEdges;
                    cnt = cnt + size(curEdges,1);
%                     seedEdges = [seedEdges;curEdges];
                end
                seedEdges(cnt+1,:) = [rootID,mapping(seed(1)),seedWeight - 1];
                cnt = cnt + 1;
%                 rootEdges = [rootEdges;rootID,mapping(seed(1)),seedWeight - 1];
            end
%             edges = [edges;seedEdges;rootEdges];
            seedEdges = seedEdges(1:cnt,:);
            edges = [edges;seedEdges];
            clear seedEdges;
            clear ih;
            clear iw;
            clear it;
            clear ee;
            clear curEdges;
            clear pix0;
            
            % MSF
            G = graph(edges(:,1),edges(:,2),edges(:,3));
            clear edges;
            Tree = minspantree(G);

            % delete root
            Tree = rmnode(Tree,rootID);
            bins = conncomp(Tree);
%             bins0 = bins(ismember(pix,actPix));
            
            % Map
            for ii = 1:numel(labels)
                seedLabel = labels(ii);
                label = bins(mapping(sdLst{seedLabel}(1)));
                curPix = pix(bins==label);
                Map(intersect(curPix,actPix)) = seedLabel;
            end
        end
     end
    curRegions = curRegions(validRegion);
    evtLst = label2idx(Map);
end
