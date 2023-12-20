function [groupStd] = getGroupStd(fg,bg,muTable,varTable,T)
% Xuelong Mi 02/15/2023
% Obtain the variance of the whole group, given bg, fg and their rank
    n1 = numel(fg);
    n2 = numel(bg);
    n = n1 + n2;
    
    labels = true(n,1);
    labels(1:n2) = false;
    all = cat(1, bg, fg);
    [~, od] = sort(all); % ascending
    labels = labels(od);

    mus = muTable(n,1:n);
    vars = varTable(n,1:n);

    mu1 = 1/n1*sum(mus(labels));
    var1 = 1/n1*sum(vars(labels) + mus(labels).^2) - mu1^2;

    mu2 = 1/n2*sum(mus(~labels));
    var2 = 1/n2*sum(vars(~labels) + mus(~labels).^2) - mu2^2;

    % correct
    % bayesian
    if n1>1
        varFg = var(fg); varFg = ((T-1)*1 + (n1-1)*varFg)/(T + n1 -1);
    else
        varFg = 1;
    end
    varFg = varFg/var1;
    if n2>1
        varBg = var(bg); varBg = ((T-1)*1 + (n2-1)*varBg)/(T + n2 -1);
    else
        varBg = 1;
    end
    varBg = varBg/var2;

    groupStd = sqrt(((n1-1)*varFg + (n2-1)*varBg)/(n1+n2-2));
end