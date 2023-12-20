function isSig = curveSignificance2(curve,t0,t1,sigThr)
    isSig = false;
    T = numel(curve);
    sigma0 = sqrt(mean((curve(2:end)-curve(1:end-1)).^2)/2);
    curve = curve/sigma0;
    curve0 = curve(t0:t1);
    maxThr = max(curve0);
    minThr = min(curve0);
    thrs = maxThr:-(maxThr-minThr)/5:minThr;
    z_Left = 0; z_Right = 0;
    for k = 1:numel(thrs)
        curThr = thrs(k);
        ts = find(curve0>=curThr,1) + t0 - 1;
        te = find(curve0>=curThr,1,'last') + t0 - 1;
        dur = te - ts + 1;
        t_Left = max(1,ts - dur):ts-1;
        t_Right = te+1:min(T,te+dur);
        if isempty(t_Left) || isempty(t_Right)
            continue;
        end
        bgL = curve(t_Left)';
        bgR = curve(t_Right)';
        fg = curve(ts:te)';

        bgL = bgL(bgL<curThr);
        bgR = bgR(bgR<curThr);

        % t - test
        if isempty(bgL) || isempty(bgR)
            continue;
        end
        tScoreL = (mean(fg)-mean(bgL))/sqrt(1/numel(fg)+1/numel(bgL));
        tScoreR = (mean(fg)-mean(bgR))/sqrt(1/numel(fg)+1/numel(bgR));
        if min(tScoreL,tScoreR)<sigThr
            continue;
        end

        [mu,sigma] = se.ordStatSmallSampleWith0s(fg,bgL,bgR);
        L = (mean(fg) - mean(bgL));
        z_Left = max(z_Left,(L-mu)/sigma);

        [mu,sigma] = se.ordStatSmallSampleWith0s(fg,bgR,bgL);
        L = (mean(fg) - mean(bgR));
        z_Right = max(z_Right,(L-mu)/sigma);

        if min([z_Left,z_Right])>sigThr
            isSig = true;
            return;
        end
    end
    
end