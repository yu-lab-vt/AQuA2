function [pvalue1,pvalue2] = calDependencySimple(sequence1, sequence2, possibleDists)
% condition is the first variable, occurrence is the second.
    index1 = find(sequence1);
    index2 = find(sequence2);
    if isempty(index1) || isempty(index2)
        pvalue1 = 1;
        pvalue2 = 1;
        return;
    end
    T = numel(sequence1);
    dist = abs(index1 - index2');
    dist1 = min(dist,[],1);
    dist2 = min(dist,[],2);
    [pvalue1] = getPvalue(numel(index1),numel(index2),T,dist1,possibleDists);
    [pvalue2] = getPvalue(numel(index2),numel(index1),T,dist2,possibleDists);
end
function [pvalue] = getPvalue(k1,k2,T,dist,possibleDists)
    % sequence 2 depend on sequence 1:
    lambda = k2/T;
    pvalues = ones(numel(possibleDists),1);
    for k = 1:numel(possibleDists)
        % dilate
        L = possibleDists(k)*2 + 1;
        x = sum(dist<=possibleDists(k));
        p = 1-exp(-lambda*L);
        pvalues(k) = binocdf(x-1,k1,p,'upper'); %>=x, >x-1
    end
    [pvalue,~] = min(pvalues);
end