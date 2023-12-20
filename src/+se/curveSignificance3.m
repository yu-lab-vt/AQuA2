function isSig = curveSignificance3(curve,t0,t1,sigThr)
    isSigLeft = false;
    isSigRight = false;
    T = numel(curve);

    % relative local? Here just assume noise related to intensity
%     maxV = max(curve(t0:t1));
%     minV = min(curve(t0:t1));
%     similar = curve<maxV*1.2 & curve>minV*0.8;
%     noise_estimation = curve;
%     noise_estimation(~similar) = nan;
%     noise_estimation = (noise_estimation(2:end) - noise_estimation(1:end-1)).^2;
%     noise_estimation = noise_estimation(~isnan(noise_estimation));
%     if numel(noise_estimation)<100
        sigma0 = sqrt(median((curve(2:end)-curve(1:end-1)).^2)/0.9099);
%     else
%         sigma0 = sqrt(median(noise_estimation)/0.9099);
%     end

    curve = curve/sigma0;
    curve0 = curve(t0:t1);
    maxThr = max(curve0);
    minThr = min(curve0);
    if maxThr==minThr
        thrs = maxThr;
    else
        thrs = maxThr:-(maxThr-minThr)/5:minThr;
    end
    for k = 1:numel(thrs)
        curThr = thrs(k);
        ts = find(curve0>=curThr,1) + t0 - 1;
        te = find(curve0>=curThr,1,'last') + t0 - 1;
        dur = te - ts + 1;
        fg = curve(ts:te)';

        t_Left_start = find(curve(1:ts-1)>=curThr,1,'last') + 1;
        if isempty(t_Left_start)
            t_Left_start = 1;
        end
        t_Left_start = max(t_Left_start,ts-dur);
        bgL = curve(t_Left_start:ts-1)';

        t_Right_end = find(curve(te+1:end)>=curThr,1) - 1 + te;
        if isempty(t_Right_end)
            t_Right_end = T;
        end
        t_Right_end = min(t_Right_end,te+dur);
        bgR = curve(te+1:t_Right_end)';
        
        if ~isempty(bgL)
            tScoreL = (mean(fg)-mean(bgL))/sqrt(1/numel(fg)+1/numel(bgL));
            if tScoreL>=sigThr
                [mu,sigma] = se.ordStatSmallSampleWith0s(fg,bgL,bgR);
                L = (mean(fg) - mean(bgL));
                z_Left = (L-mu)/sigma;
                if z_Left>=sigThr
                    isSigLeft = true;
                end
            end
        end

        if ~isempty(bgR)
            tScoreR = (mean(fg)-mean(bgR))/sqrt(1/numel(fg)+1/numel(bgR));
            if tScoreR>=sigThr
                [mu,sigma] = se.ordStatSmallSampleWith0s(fg,bgR,bgL);
                L = (mean(fg) - mean(bgR));
                z_Right = (L-mu)/sigma;
                if z_Right>=sigThr
                    isSigRight = true;
                end
            end
        end
    end
    isSig = isSigLeft & isSigRight;
end