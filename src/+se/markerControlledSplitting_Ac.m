function [evtLst,sdLst,curRegions] = markerControlledSplitting_Ac(Map,curRegions,dF,opts,ff)
% ----------- Modified by Xuelong Mi, 02/20/2023 -----------
    [H,W,L,T] = size(dF);
    sdLst = label2idx(Map);
    opts.spaSmo = 3;
    scoreMap = zeros([H,W,L,T],"single");
    for t = 1:T
        scoreMap(:,:,:,t) = -imgaussfilt(dF(:,:,:,t),opts.spaSmo);% spatial smoothing for weakening gap in spatial
    end
    clear dF;
    clear dFOrg;
    % calculate scoreMap
    if L==1
        SE = strel(true(8,8,8));
    else
        SE = strel(true(8,8,8,8));
    end

    seedsInRegion = cell(numel(curRegions),1);
    % check whether the whole active region is significant or not
    for i = 1:numel(curRegions)
         pix = curRegions{i};
         labels = setdiff(Map(pix),0);         
         if(numel(labels) == 1)
            Map(pix) = labels(1);
         end
         seedsInRegion{i} = labels;
    end
            
    % watershed
     splitRegion = cell(numel(curRegions),1);
     for i = 1:numel(curRegions)
        if exist('ff','var')&&~isempty(ff)
            waitbar(0.4 + 0.3*i/numel(curRegions),ff);
        end
        labels = seedsInRegion{i};
        if(numel(labels)>1)
            pix = curRegions{i};
            [ih,iw,il,it] = ind2sub([H,W,L,T],pix);
            % Multiple seeds, need to split 
            rgh = min(ih):max(ih); H0 = numel(rgh); ih = ih - min(ih) + 1;
            rgw = min(iw):max(iw); W0 = numel(rgw); iw = iw - min(iw) + 1;
            rgl = min(il):max(il); L0 = numel(rgl); il = il - min(il) + 1;
            rgt = min(it):max(it); T0 = numel(rgt); it = it - min(it) + 1;
            pix0 = sub2ind([H0,W0,L0,T0],ih,iw,il,it);
            % Map seed regions
            Map0 = zeros(H0,W0,L0,T0,'uint16');
            Map0(pix0) = Map(pix);
            % watershed input
            scoreMap0 = scoreMap(rgh,rgw,rgl,rgt);
            % deal with background
            BW = true(size(Map0));
            BW(pix0) = false;
            if L==1
                BW = permute(BW,[1,2,4,3]);
                Map0 = permute(Map0,[1,2,4,3]);
                scoreMap0 = permute(scoreMap0,[1,2,4,3]);
            end
            BW2 = imerode(BW,SE);
            scoreMap0(BW) =  max(scoreMap0(pix0))+1;
            scoreMap0(BW2) = -100;
            scoreMap1 = imimposemin(scoreMap0,Map0>0|BW2);
            % marker-controlled splitting
            MapOut = watershed(scoreMap1);
            if L==1
                MapOut = permute(MapOut,[1,2,4,3]);
            end
            % update
            MapOut(BW) = 0;
            waterLst = label2idx(MapOut);
            curLoc = cell(numel(labels),1);
            labelMapping = zeros(max(labels),1);
            labelMapping(labels) = 1:numel(labels);
            for ii = 1:numel(waterLst)
                curPix = waterLst{ii};
                curLabel = setdiff(Map0(curPix),0);
                label = labelMapping(curLabel);
                if isempty(label) 
                    continue; 
                end

                % find the largest connected component
                BW00 = false(H0,W0,L0,T0);
                BW00(curPix) = true;
                cc = bwconncomp(BW00).PixelIdxList;
                sz = cellfun(@numel,cc);

                % the target must include seed
                cc = cc(sz>=numel(sdLst{curLabel}));
                id = 1;
                for j = 1:numel(cc)
                    if sum(Map0(cc{j}))>0
                        id = j;
                        break;
                    end
                end
                curPix = cc{id};

                % update
                [ch,cw,cl,ct] = ind2sub([H0,W0,L0,T0],curPix);
                ch = ch + min(rgh) - 1;
                cw = cw + min(rgw) - 1;
                cl = cl + min(rgl) - 1;
                ct = ct + min(rgt) - 1;
                curLoc{label} = [curLoc{label};sub2ind([H,W,L,T],ch,cw,cl,ct)];
            end
            splitRegion{i} = curLoc;
        end
     end
     
    % update Map, grow one circle to remove gap
    [x_dir,y_dir,z_dir,t_dir] = se.dirGenerate(80); 
    validRegion = false(numel(curRegions),1);
    for i = 1:numel(curRegions)
        labels = seedsInRegion{i};
        if(~isempty(labels))
            validRegion(i) = true;
        end
        if(numel(labels)>1)
           for ii = 1:numel(labels)
               pix = splitRegion{i}{ii};
               Map(pix) = labels(ii);
           end
           pix = curRegions{i};
           pix = pix(Map(pix)==0);
           while ~isempty(pix)
               [ih0,iw0,il0,it0] = ind2sub([H,W,L,T],pix);
               for k = 1:numel(x_dir)
                    ih = max(1,min(H,ih0+x_dir(k)));
                    iw = max(1,min(W,iw0+y_dir(k)));
                    il = max(1,min(L,il0+z_dir(k)));
                    it = max(1,min(T,it0+t_dir(k)));
                    pixCur = sub2ind([H,W,L,T],ih,iw,il,it);
                    select = Map(pixCur)>0;
                    Map(pix(select)) = Map(pixCur(select));
                    ih0 = ih0(~select);
                    iw0 = iw0(~select);
                    il0 = il0(~select);
                    it0 = it0(~select);
                    pix = pix(~select);
               end
           end
        end
    end
    evtLst = label2idx(Map);
    curRegions = curRegions(validRegion);
end
