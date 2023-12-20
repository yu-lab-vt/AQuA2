function ihw = getMajoritySpa(pix,TW,sz,opts)

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
    majorThr = opts.major;
    select = [];

    % in case no large major part
    while(numel(select)<opts.minSize)
        select = find(a_counts>=dur*majorThr);
        majorThr = majorThr-0.1; 
        if(majorThr<0)
            break;
        end
    end
    ihw = ihw(select);

    % 2D largest connected component
    Map = false(H,W);
    Map(ihw) = true;
    pixLst = bwconncomp(Map);
    pixLst = pixLst.PixelIdxList;
    areaSz = cellfun(@numel,pixLst);
    [~,id] = max(areaSz);
    ihw = pixLst{id};
end