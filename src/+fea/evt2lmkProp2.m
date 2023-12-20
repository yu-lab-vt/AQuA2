function [minDistToLandMark, maxDistToLandMark] = evt2lmkProp2(datS,msk0,thrRg, muPerPix)
% rewritten by Xuelong Mi

[H,W,~,~] = size(datS);
nThr = numel(thrRg);

sck = max(round(sqrt(H*W/10000)),1);
datSx = imresize(datS,1/sck);  % acceleration but may introduce artifacts

lmkMsk = imresize(msk0,1/sck);
lmkMskBd = find(bwperim(lmkMsk));

[H,W,L,T] = size(datSx);

minDistToLandMark = nan(T,nThr);
maxDistToLandMark = nan(T,nThr);

for kk=1:nThr
    evt0 = datSx>thrRg(kk);
    loc0 = find(evt0>0);
    
    [~,~,~,it] = ind2sub([H,W,L,T],loc0);
    t0 = min(it);
    t1 = max(it);
    for t = t0:t1
        curMap = evt0(:,:,:,t);
        curBound = find(bwperim(curMap));
        [ih1,iw1,il1] = ind2sub([H,W,L],curBound);
        if isempty(ih1)
            continue;
        end

        msk0 = lmkMsk;
        [ih0,iw0,il0] = ind2sub([H,W,L],lmkMskBd);
        maxDist = 0;
        minDist = inf;
        for ii = 1:numel(ih1)
            if ~msk0(curBound(ii))
                delta = [(ih1(ii)-ih0)*sck,(iw1(ii)-iw0)*sck,il1(ii)-il0];
                dist = sqrt(sum(delta.^2,2));
                maxDist = max(maxDist,max(dist(:)));
                minDist = min(minDist,min(dist(:)));
            end
        end
        
        if sum(curMap(:) & msk0(:))>0
            minDistToLandMark(t,kk) = 0;
        end
        minDistToLandMark(t,kk) = minDist * muPerPix;
        maxDistToLandMark(t,kk) = maxDist * muPerPix;
    end
end

end