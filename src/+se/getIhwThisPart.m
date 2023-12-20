function ihw = getIhwThisPart(pix,TW,sz,majorThr)

    t00 = min(TW);
    t11 = max(TW);
    H = sz(1); W = sz(2); T = sz(3);

    %% Spatial majority
    dur = t11-t00+1;
    [ih,iw,it]  = ind2sub([H,W,T],pix);
    select = it>=t00 & it<=t11;   % seed Time Window
    ihSelect = ih(select);
    iwSelect = iw(select);
    [ihw,~,ic] = unique(sub2ind([H,W],ihSelect,iwSelect));
    a_counts = accumarray(ic,1);
    select = [];

    % in case no large major part
    select = find(a_counts>=dur*majorThr);
    ihw = ihw(select);
    
    if(isempty(ihw))
        return;
    end

    % 2D largest connected component
    Map = false(H,W);
    Map(ihw) = true;
    pixLst = bwconncomp(Map);
    pixLst = pixLst.PixelIdxList;
    areaSz = cellfun(@numel,pixLst);
    [~,id] = max(areaSz);
    ihw = pixLst{id};
end