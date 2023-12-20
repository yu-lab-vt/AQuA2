function [bias] = obtainBias(winSize,cut)
% Xuelong Mi 02/09/2023
% check table to obtain bias
load('F0_biasMatrix.mat');
if winSize>cut
    % in case winSize > cut and return nan value
    bias = 0;
    return;
end

% linear interpolate value if cannot find it
idx0 = find(winSize>=windowSizes,1,'last');
idy0 = find(cut>=cuts,1,'last');
if idx0==numel(windowSizes) || windowSizes(idx0) == winSize
    idx1 = idx0;
else
    idx1 = idx0 + 1;
end
if idy0==numel(cuts) || cuts(idy0) == cut
    idy1 = idy0;
else
    idy1 = idy0 + 1;
end

bias0 = nanmean(biasMatrix([idx0,idx1],idy0));
bias1 = nanmean(biasMatrix([idx0,idx1],idy1));
cut0 = cuts(idy0);
cut1 = cuts(idy0+1);

if isnan(bias0)
    bias = bias1;
else
    bias = bias0 + (bias1-bias0)/(cut1-cut0)*(cut-cut0);
end

end