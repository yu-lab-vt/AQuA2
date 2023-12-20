function [score1,score2] = calTScore(fg,bg1,bg2)
    score1 = inf;score2 = inf;
    if(~isempty(bg1))
       L1 = mean(fg) - mean(bg1);
       sigma1 = sqrt(1/numel(fg)+1/numel(bg1));
       score1 = L1/sigma1;
    end
    if(~isempty(bg2))
       L2 = mean(fg) - mean(bg2);
       sigma2 = sqrt(1/numel(fg)+1/numel(bg2));
       score2 =  L2/sigma2;
   end
end