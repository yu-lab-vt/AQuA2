function [z_score1,z_score2,t_score1,t_score2] = getSeedScore2(pix,spa_scl,t_scl,datOrg,orgDataSize)
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

    if isempty(fgPix)
        z_score1 = 0;
        z_score2 = 0;
        t_score1 = 0;
        t_score2 = 0;
        return
    end

    %% find neighbor
    [ih,iw,il,it] = ind2sub([H0,W0,L0,T0],fgPix);
%     [ih0,iw0,il0,it0] = ind2sub([H0,W0,L0,T0],fgPix0);
%   ihw0 = sub2ind([H0,W0,L0],ih0,iw0,il0);
    ihwOrg = sub2ind([H0,W0,L0],ih,iw,il);
    ihw = unique(ihwOrg);

    z_Left = zeros(numel(ihw),1);
    z_Right = zeros(numel(ihw),1);
    sz = zeros(1,numel(ihw));

    fgAll = cell(numel(ihw),1);
    bgL = cell(numel(ihw),1);
    bgR = cell(numel(ihw),1);
    noise = [];

    for i = 1:numel(ihw)
        curIt = it(ihw(i) == ihwOrg);
        [curIh,curIw,curIl] = ind2sub([H0,W0,L0],ihw(i));
        % get normalized downsampled curve
        curve0 = squeeze(datOrg(curIh,curIw,curIl,:));
        curve = se.myResize(curve0,1/t_scl)*sqrt(t_scl);
        dur = numel(curIt);
        sz(i) = dur;
        
        t0 = min(curIt);
        t1 = max(curIt);        

        t_Left = max(1,t0-dur):t0-1;
        t_Right = t1+1:min(T0,t1+dur);

        fgAll{i} = curve(curIt);
        bgL{i} = curve(t_Left);
        bgR{i} = curve(t_Right);

        if ~isempty(t_Left)
            t0 = max(2,min(t_Left)*t_scl);
            t1 = max(t_Left)*t_scl;
            difL = (curve0(t0:t1) - curve0((t0-1):(t1-1))).^2;
        else
            difL = [];
        end

        if ~isempty(t_Right)
            t0 = min(t_Right)*t_scl;
            t1 = min(max(t_Right)*t_scl,T-1);
            difR = (curve0(t0:t1) - curve0((t0+1):(t1+1))).^2;
        else
            difR = [];
        end
        noise = [noise;difL;difR];
    end

    fg0 = cell2mat(fgAll); fg0 = fg0(~isnan(fg0));
    bkL = cell2mat(bgL); bkL = bkL(~isnan(bkL));
    bkR = cell2mat(bgR); bkR = bkR(~isnan(bkR));
    n1 = numel(bkL);
    n2 = numel(bkR);
    if n1 + n2<=2 || n1<=1 || n2<=1 || numel(noise)<=2
        z_score1 = 0;
        z_score2 = 0;
        t_score1 = 0;
        t_score2 = 0;
        return;
    end
%     sigmaL = std(bkL);
%     sigmaR = std(bkR);
%     sigma0 = sqrt((sigmaL^2*(n1-1) + sigmaR^2*(n2-1)) / (n1+n2-2));
    sigma0 = sqrt(mean(noise)/2)/sqrt(t_scl);

    for i = 1:numel(ihw)
        fg = fgAll{i}/sigma0; bg1 = bgL{i}/sigma0; bg2 = bgR{i}/sigma0;
        if ~isempty(bg1)
            L = (mean(fg) - mean(bg1));
            [mu,sigma] = se.ksegments_orderstatistics_fin(fg,bg1);
            z_Left(i) = (L-mu)/sigma;
        end
        if ~isempty(bg2)
            L = (mean(fg) - mean(bg2));
            [mu,sigma] = se.ksegments_orderstatistics_fin(fg,bg2);
            z_Right(i) = (L-mu)/sigma;
        end
    end

    z_score1 = sqrt(sz)*z_Left/sqrt(sum(sz));
    z_score2 = sqrt(sz)*z_Right/sqrt(sum(sz));

    t_score1 = 0;
    fg0 = fg0/sigma0;
    bkL = bkL/sigma0;
    bkR = bkR/sigma0;

    if ~isempty(bkL)
        t_score1 = (mean(fg0)-mean(bkL))/sqrt(1/numel(fg0)+1/numel(bkL));
    end
    t_score2 = 0;
    if ~isempty(bkR)
        t_score2 = (mean(fg0)-mean(bkR))/sqrt(1/numel(fg0)+1/numel(bkR));
    end

    % t_distribution
    z_score1 = -norminv(tcdf(z_score1,numel(noise)-1,'upper'));
    z_score2 = -norminv(tcdf(z_score2,numel(noise)-1,'upper'));

    t_score1 = -norminv(tcdf(t_score1,numel(noise)-1,'upper'));
    t_score2 = -norminv(tcdf(t_score2,numel(noise)-1,'upper'));
end