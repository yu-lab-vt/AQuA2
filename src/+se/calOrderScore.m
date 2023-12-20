function [score1,score2] = calOrderScore(fg,bg1,bg2,nv1,nv2)
    score1 = inf;score2 = inf;    
    fg = double(fg);bg1 = double(bg1);bg2 = double(bg2);
    if(~exist('nv1','var'))
        if(~isempty(bg1))
           L1 = mean(fg) - mean(bg1);
           [mu1, sigma1] = se.ksegments_orderstatistics_fin(fg, bg1);
           score1 = (L1-mu1)/sigma1;
        end
        if(~isempty(bg2))
           L2 = mean(fg) - mean(bg2);
           [mu2, sigma2] = se.ksegments_orderstatistics_fin(fg, bg2);
           score2 = (L2-mu2)/sigma2;
       end
    else
        if(~isempty(bg1))
            nv1 = double(nv1);
            L1 = mean(fg) - mean(bg1);
            [mu1, sigma1] = se.ordStatApproxKsecWith0s(fg, bg1, nv1);
            score1 = (L1-mu1)/sigma1;

        end
        if(~isempty(bg2))
            nv2 = double(nv2);
            L2 = mean(fg) - mean(bg2);
            [mu2, sigma2] = se.ordStatApproxKsecWith0s(fg, bg2, nv2);
            score2 = (L2-mu2)/sigma2;
       end
    end
end