function [z_score1,z_score2,t_score1,t_score2] = getSeedScore(pix,spa_scl,t_scl,datOrg,orgDataSize)
    %% downsample
    H = orgDataSize(1);
    W = orgDataSize(2);
    L = orgDataSize(3);
    T = orgDataSize(4);

    [ih,iw,il,it] = ind2sub([H,W,L,T],pix);

    % only do dosample in X,Y dimension
    ih = ceil(ih/spa_scl);
    iw = ceil(iw/spa_scl);
%     il = il;
    it = ceil(it/t_scl);
    
    H0 = floor(H/spa_scl);
    W0 = floor(W/spa_scl);
    L0 = L;
    T0 = floor(T/t_scl);
    
    select = ih<=H0 & iw<=W0 & it<=T0;
    pix0 = sub2ind([H0,W0,L0,T],ih(select),iw(select),il(select),it(select));
    [C,~,ic] = unique(pix0);
    a_counts = accumarray(ic,1);
    fgPix = C(a_counts>spa_scl*spa_scl*t_scl/2);

    fgAll = zeros(size(fgPix));
    bgL = zeros(size(fgPix));
    bgR = zeros(size(fgPix));

    if isempty(fgPix)
        z_score1 = 0;
        z_score2 = 0;
        t_score1 = 0;
        t_score2 = 0;
        return
    end

    %% find neighbor
    [ih,iw,il,it] = ind2sub([H0,W0,L0,T0],fgPix);
    ihwOrg = sub2ind([H0,W0,L0],ih,iw,il);
    ihw = unique(ihwOrg);

    z_Left = zeros(numel(ihw),1);
    z_Right = zeros(numel(ihw),1);
    sz = zeros(1,numel(ihw));
  
    cnt = 0;
    cnt1 = 0;
    cnt2 = 0;

    for i = 1:numel(ihw)
        it0 = it(ihw(i) == ihwOrg);
        [curIh,curIw,curIl] = ind2sub([H0,W0,L0],ihw(i));
        % get normalized downsampled curve
        curve = se.myResize(squeeze(datOrg(curIh,curIw,curIl,:)),1/t_scl)*sqrt(t_scl);
        
        t0 = min(it0);
        t1 = max(it0);
        dur = numel(it0);
        sz(i) = dur;

        t_Left = max(1,t0-dur):t0-1;
        t_Right = t1+1:min(T0,t1+dur);

        nLeft = numel(t_Left);
        nRight = numel(t_Right);

        fg = curve(it0);
        bg1 = curve(t_Left);
        bg2 = curve(t_Right);

        fgAll(cnt+1:cnt+dur) = fg;
        bgL(cnt1+1:cnt1+nLeft) = bg1;
        bgR(cnt2+1:cnt2+nRight)= bg2;

        cnt = cnt + dur;
        cnt1 = cnt1 + nLeft;
        cnt2 = cnt2 + nRight;

        % evaluate significance on each pixel
        if ~isempty(bg1)
            L = mean(fg) - mean(bg1);
            [mu,sigma] = se.ksegments_orderstatistics_fin(fg,bg1);
            z_Left(i) = (L-mu)/sigma;
        end
        if ~isempty(bg2)
            L = mean(fg) - mean(bg2);
            [mu,sigma] = se.ksegments_orderstatistics_fin(fg,bg2);
            z_Right(i) = (L-mu)/sigma;
        end

    end

    fgAll = fgAll(1:cnt);
    bgL = bgL(1:cnt1);
    bgR = bgR(1:cnt2);

    z_score1 = sqrt(sz)*z_Left/sqrt(sum(sz));
    z_score2 = sqrt(sz)*z_Right/sqrt(sum(sz));
    t_score1 = 0;
    if ~isempty(bgL)
        t_score1 = (mean(fgAll)-mean(bgL))/sqrt(1/numel(fgAll)+1/numel(bgL));
    end
    t_score2 = 0;
    if ~isempty(bgR)
        t_score2 = (mean(fgAll)-mean(bgR))/sqrt(1/numel(fgAll)+1/numel(bgR));
    end
end