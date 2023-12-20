function [polyMask,polyCenter,polyBorder,polyAvgDist] = getPolyInfo(polyLst,sz)
nPoly = length(polyLst);
polyMask = cell(nPoly,1);
polyCenter = nan(nPoly,3);
polyBorder = cell(nPoly,1);  % boundary pixels
polyAvgDist = nan(nPoly,1);
for ii=1:nPoly
    poly0 = polyLst{ii};
    if ~isempty(poly0)
        msk = false(sz(1:3));
        msk(poly0) = true;
        polyMask{ii} = msk;
        [ih,iw,il] = ind2sub(sz(1:3),poly0);
        rCentroid = [round(mean(ih)),round(mean(iw)),round(mean(il))];
        polyCenter(ii,:) = rCentroid;
        mskBd = bwperim(msk);
        [ix,iy,iz] = ind2sub(sz(1:3),find(mskBd));
        polyBorder{ii} = [ix,iy,iz];
        polyAvgDist(ii) = max(round(median(sqrt((rCentroid(1)-ix).^2 + (rCentroid(2)-iy).^2 + (rCentroid(3)-iz).^2))),1);
    end
end
end