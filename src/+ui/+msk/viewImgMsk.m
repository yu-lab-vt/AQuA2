function viewImgMsk(~, ~, f,stg)

    fh = guidata(f);
    ax = fh.imgMsk;
    im = fh.imsMsk;
    if ~exist('stg')
        stg = 0;
    end
    hh = findobj(ax, 'Type', 'text');
    delete(hh);

    bd = getappdata(f, 'bd');
    bdMsk = bd('maskLst');

    tbDat = cell2mat(fh.mskTable.Data(:, 1));
    ix = find(tbDat, 1);

    rr = bdMsk{ix};
    if ~strcmp(rr.type,'region') && ~strcmp(rr.type,'landmark') && strcmp(rr.type,'regionMarker') 
        return;
    end

    datAvg = rr.datAvg;
    [H, W, L] = size(datAvg);

    if(stg==0)
        % remove too small and too large
        mskx = datAvg >= rr.thr;
        if ~(strcmp(rr.type,'background') || strcmp(rr.type,'foreground'))
            if rr.morphoChange<0
                mskx = imerode(mskx,strel('disk',-rr.morphoChange));
            elseif rr.morphoChange>0
                mskx = imdilate(mskx,strel('disk',rr.morphoChange));
            end

            cc = bwconncomp(mskx);
            ccSz = cellfun(@numel, cc.PixelIdxList);
            cc.PixelIdxList = cc.PixelIdxList(ccSz <= rr.maxSz & ccSz >= rr.minSz);
            cc.NumObjects = numel(cc.PixelIdxList);
            mskx = labelmatrix(cc);
        end

        % save mask
        rr.mask = mskx;
    end
    bdMsk{ix} = rr;
    bd('maskLst') = bdMsk;
    setappdata(f, 'bd', bd);
    
    mskb = zeros(H, W, L);

    if L==1
        % get boundary for drawing
        bLst = bwboundaries(rr.mask > 0);
        for ii = 1:numel(bLst)
            ix = bLst{ii};
            ix = sub2ind([H, W], ix(:, 1), ix(:, 2));
            mskb(ix) = 1;
        end 
        d1 = datAvg;
        d1(mskb>0) = d1(mskb>0)*0.7+mskb(mskb>0)*0.5;    
        datx = cat(3, d1, datAvg, datAvg);
    
        im.CData = datx(end:-1:1,:,:);
        ax.XLim = [1, W];
        ax.YLim = [1, H];
    else
        dsSclXY = fh.sldDsXYMsk.Value;
        im.Data = se.myResize(datAvg,1/dsSclXY);
        alphaMap = zeros(size(rr.mask),'single');
        alphaMap(rr.mask>0) = 1-fh.sldIntensityTransMsk.Value;
        im.AlphaData = se.myResize(alphaMap,1/dsSclXY);
    end

end 
