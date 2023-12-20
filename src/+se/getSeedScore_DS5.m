function [z_score1,z_score2,t_score1,t_score2] = getSeedScore_DS5(pix,t_scl,datVec,sz)
    %% downsample
    H = sz(1); W = sz(2); L = sz(3); T = sz(4);
    [ih,iw,il,it] = ind2sub([H,W,L,T],pix);
    it = ceil(it/t_scl);
    T0 = floor(T/t_scl);
    
    select = it<=T0;
    pix0 = sub2ind([H,W,L,T0],ih(select),iw(select),il(select),it(select));
    [C,~,ic] = unique(pix0);
    a_counts = accumarray(ic,1);
    fgPix = C(a_counts>t_scl/2);

    if isempty(fgPix)
        z_score1 = 0;
        z_score2 = 0;
        t_score1 = 0;
        t_score2 = 0;
        return
    end

    %% find neighbor
    [ih,iw,il,it] = ind2sub([H,W,L,T0],fgPix);
    ihwOrg = sub2ind([H,W,L],ih,iw,il);
    ihw = unique(ihwOrg);

    sz = zeros(1,numel(ihw));

    fgAll = cell(numel(ihw),1);
    bgL = cell(numel(ihw),1);
    bgR = cell(numel(ihw),1);
    nanVec = cell(numel(ihw),1);
    noise = [];
    for i = 1:numel(ihw)
        curIt = it(ihw(i) == ihwOrg);
        % get normalized downsampled curve
        curve0 = datVec(ihw(i),:)';
        curve = se.myResize(curve0,1/t_scl)*sqrt(t_scl);
        dur = numel(curIt);
        sz(i) = dur;
        
        t0 = min(curIt);
        t1 = max(curIt);        

        t_Left = max(1,t0-dur):t0-1;
        t_Right = t1+1:min(T0,t1+dur);

        fg = curve(curIt);
        fgAll{i} = fg;
        bgL{i} = curve(t_Left);
        bgR{i} = curve(t_Right);
        nanV = curve(setdiff(t0:t1,curIt));
        nanVec{i} = nanV;

        curveL = [];
        if ~isempty(t_Left)
            t0 = max(2,min(t_Left));
            t1 = max(t_Left);
            curveL = curve(t0-1:t1);
        end

        curveR = [];
        if ~isempty(t_Right)
            t0 = min(t_Right);
            t1 = min(max(t_Right),T-1);
            curveR = curve(t0:t1+1);
        end
        
        noise = [noise;se.getLocalDifSquare(curveL,curveR,nanV,fg)];
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
    
    sigma0 = sqrt(mean(noise)/2);
    
    %
    mus_Left = zeros(1,numel(ihw));
    L_left = -inf(1,numel(ihw));
    mus_Right = zeros(1,numel(ihw));
    L_right = -inf(1,numel(ihw));

    for i = 1:numel(ihw)
        fg = fgAll{i}/sigma0; bg1 = bgL{i}/sigma0; bg2 = bgR{i}/sigma0; nanV = nanVec{i}/sigma0;
        if ~isempty(bg1)
            L = (mean(fg) - mean(bg1));
            [mu,sigma] = se.ordStatSmallSampleWith0s(fg,bg1,[bg2;nanV]);            
            mus_Left(i) = mu/sigma;
            L_left(i) = L/sigma;
            
        end
        if ~isempty(bg2)
            L = (mean(fg) - mean(bg2));
            [mu,sigma] = se.ordStatSmallSampleWith0s(fg,bg2,[bg1;nanV]);
            mus_Right(i) = mu/sigma;
            L_right(i) = L/sigma;
        end
    end

    z_Left = -norminv(nctcdf(L_left,numel(noise)-1,mus_Left,'upper'))';
    z_Right = -norminv(nctcdf(L_right,numel(noise)-1,mus_Right,'upper'))';

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

    if numel(noise)<100
        t_score1 = -norminv(tcdf(t_score1,numel(noise)-1,'upper'));
        t_score2 = -norminv(tcdf(t_score2,numel(noise)-1,'upper'));
    end
end