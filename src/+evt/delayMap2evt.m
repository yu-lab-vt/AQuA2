function [svLabel] = delayMap2evt(dlyMap,major0,opts)
% ----------- Modified by Xuelong Mi, 02/28/2023 -----------
% cluster super voxels to events
%% source detection
[H,W,L] = size(dlyMap);
[dh,dw,dl] = se.dirGenerate(26);
minDly = nanmin(dlyMap(:));
maxDly = nanmax(dlyMap(:));

if opts.sourceSensitivity==10   % The highest sensitivity
    delayThr = 1;
else
    delayThr = opts.TPatch*(10-opts.sourceSensitivity)/10;
end

svLabel = zeros(numel(major0),1);
if maxDly-minDly<delayThr
    svLabel(:) = 1;
    return;
end
ihw = find(~isnan(dlyMap));
thrs = minDly:(maxDly-minDly)/opts.TPatch:maxDly;
seedMap = zeros(H,W,L);
nSeed = 0;
for k = 1:numel(thrs)    
    thr = thrs(k);
    candidateRegions = act.bw2Reg(dlyMap<thr,opts);
    sz = cellfun(@numel,candidateRegions);
    candidateRegions = candidateRegions(sz>max(numel(ihw)*opts.sourceSzRatio,opts.minSize));
    for i = 1:numel(candidateRegions)
        pix = candidateRegions{i};
        seedsInRegion = setdiff(seedMap(pix),0);
        if(numel(seedsInRegion)==1) % grow, like watershed
            seedMap(pix) = seedsInRegion(1);
        elseif(numel(seedsInRegion)==0) % judge whether it is a source
            newAdd = pix;
            neighbor = [];
            pixGrow = pix;
            round = 0;
            while(round<100 && numel(newAdd)>0 && numel(neighbor)<numel(pix))
                [ih0,iw0,il0] = ind2sub([H,W,L],newAdd);
                newAdd = [];
                for ii = 1:numel(dh)
                    ih = min(max(1,ih0 + dh(ii)),H);
                    iw = min(max(1,iw0 + dw(ii)),W);
                    il = min(max(1,il0 + dl(ii)),L);
                    newAdd = [newAdd;sub2ind([H,W,L],ih,iw,il)];
                end
                newAdd = setdiff(newAdd,pixGrow);
                newAdd = newAdd(~isnan(dlyMap(newAdd)));
                neighbor = [neighbor;newAdd];
                pixGrow = [pixGrow;newAdd];
                round = round + 1;
            end
            if(mean(dlyMap(neighbor)) - nanmean(dlyMap(pix))>delayThr)
                nSeed = nSeed + 1;
                seedMap(pix) = nSeed;
            end
        end
    end
end


if(max(seedMap(:))<=1)
    svLabel(:) = 1;
    return;
end

%% watershed 
if L==1
    SE = strel('disk',2);
    BW = false(H,W,L);
    BW(ihw) = true;
    BW = imdilate(BW,strel('disk',opts.spaMergeDist));
else
    SE = strel('sphere',2);
    BW = false(H,W,L);
    BW(ihw) = true;
    BW = imdilate(BW,strel('sphere',opts.spaMergeDist));
end

scoreMap0 = dlyMap;
scoreMap0(isnan(scoreMap0)) = maxDly;
BW = ~BW;
BW2 = imerode(BW,SE);
scoreMap0(BW) = maxDly+100;
scoreMap0(BW2) = 0;
scoreMap1 = imimposemin(scoreMap0,seedMap>0|BW2);
MapOut = watershed(scoreMap1);

% update
MapOut(BW) = 0;
waterLst = label2idx(MapOut);
for ii = 1:numel(waterLst)
   pix = waterLst{ii};
   seedLabel = setdiff(seedMap(pix),0);
   if ~isempty(seedLabel)
        seedMap(pix) = seedLabel;
   end
end

% fill the ridge
ihw = ihw(seedMap(ihw)==0);
while ~isempty(ihw)
   [ih0,iw0,il0] = ind2sub([H,W,L],ihw);
   for k = 1:numel(dh)
        ih = max(1,min(H,ih0+dh(k)));
        iw = max(1,min(W,iw0+dw(k)));
        il = max(1,min(L,il0+dl(k)));
        pixCur = sub2ind([H,W,L],ih,iw,il);
        select = seedMap(pixCur)>0;
        seedMap(ihw(select)) = seedMap(pixCur(select));
        ih0 = ih0(~select);
        iw0 = iw0(~select);
        il0 = il0(~select);
        ihw = ihw(~select);
   end
end

% find the corresponding source for each subevent
for i = 1:numel(major0)
   ihw = major0{i}.ihw;
   svLabel(i) = mode(seedMap(ihw));
end

lst = label2idx(svLabel);
sz = cellfun(@numel,lst);
lst = lst(sz>0);
for i = 1:numel(lst)
    svLabel(lst{i}) = i;
end

end

