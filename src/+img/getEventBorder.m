function bds = getEventBorder(locAbs,sz)
% getEvtBorder draw boundary for each event

H = sz(1); W = sz(2); L = sz(3); T = sz(4);
if L == 1
    nEvt = numel(locAbs);
    bds = cell(nEvt,1);
    for nn=1:numel(locAbs)
        idx = locAbs{nn};
        if isempty(idx)
            continue
        end
        
        [ih,iw,il,~] = ind2sub([H,W,L,T],idx);
        ihw = unique(sub2ind([H,W,L],ih,iw,il));
        [ih,iw,il] = ind2sub([H,W,L],ihw);
        
        % crop out this region
        ih0 = max(min(ih)-2,1);
        iw0 = max(min(iw)-2,1);
        il0 = max(min(il)-2,1);
        ih1 = min(max(ih)+2,H);
        iw1 = min(max(iw)+2,W);
        il1 = min(max(il)+2,L);
        
        H1 = ih1 - ih0 + 1;
        W1 = iw1 - iw0 + 1;
        L1 = il1 - il0 + 1;
        
        ihOfst = ih-ih0+1;
        iwOfst = iw-iw0+1;
        ilOfst = il-il0+1;
        
        tmp = false(H1,W1,L1);
        tmp(sub2ind([H1,W1,L1],ihOfst,iwOfst,ilOfst)) = true;
        
        % find boundary
        tmp = bwmorph(tmp,'close');
        B = bwboundaries(tmp,4);
        
        for ii=1:numel(B)
            B0 = B{ii};
            B0(:,1) = B0(:,1) + ih0 - 1;
            B0(:,2) = B0(:,2) + iw0 - 1;
            B{ii} = B0;                
        end    
        bds{nn} = B;
    end
else
    bds = [];
end

end






