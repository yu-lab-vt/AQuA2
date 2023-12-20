function riseLst = addToRisingMap(riseLst,evtL,dlyMaps,nEvt,rgh,rgw,rgl)
% modified by Xuelong Mi 02/24/2023
% split the rising time map to different events
nEvt0 = max(evtL(:));
[H,W,L,T] = size(evtL);
for ii=1:nEvt0
    pix = find(evtL==ii);
    [ihr,iwr,ilr,~] = ind2sub([H,W,L,T],pix);
    ihw = unique(sub2ind([H,W,L],ihr,iwr,ilr));
    rghr = min(ihr):max(ihr);
    rgwr = min(iwr):max(iwr);
    rglr = min(ilr):max(ilr);

    mask = false(H,W,L);
    mask(ihw) = true;
    
    rr = [];
    rr.rgh = min(rgh)+rghr-1;
    rr.rgw = min(rgw)+rgwr-1;
    rr.rgl = min(rgl)+rglr-1;
    
    % 50% rising time map
    dlyMapr = dlyMaps{2};
    dlyMapr(~mask) = nan;
    dlyMapr = dlyMapr(rghr,rgwr,rglr);
    rr.dlyMap50 = dlyMapr;
    
    % 80% rising time map
    dlyMapr = dlyMaps{3};
    dlyMapr(~mask) = nan;
    dlyMapr = dlyMapr(rghr,rgwr,rglr);
    rr.dlyMap80 = dlyMapr;
    
    % 20% rising time map
    dlyMapr = dlyMaps{1};
    dlyMapr(~mask) = nan;
    dlyMapr = dlyMapr(rghr,rgwr,rglr);
    rr.dlyMap20 = dlyMapr;

    maxDly = ceil(quantile(rr.dlyMap80(:),0.98));
    minDly = floor(quantile(rr.dlyMap20(:),0.02));
    rr.maxDly = maxDly;
    rr.minDly = minDly;
    
    riseLst{nEvt+ii} = rr;
end
end