function [mu, sigma] = ordStatSmallSampleWith0s(fg, bg, nanVec)
% by Xuelong 04/25/2023
% The expectation and standard deviation for variable: mean(fg)-mean(bg),
% with the ranking of [fg,bg,nanVec]
global mus
global covMatrixs
if ~exist('nanVec','var')
    nanVec = [];
end

if isempty(fg) && isempty(bg)
    mu = nan;
    sigma = nan;
    return;
end
M = length(fg);
N = length(bg);
nanLen = length(nanVec);
n = M+N+nanLen;

all = cat(1, bg(:), fg(:), nanVec(:));
labels = cat(1, -ones(N,1), ones(M,1), zeros(nanLen,1));
[~, od] = sort(all); % ascending
labels = labels(od);

if isempty(mus) || isempty(covMatrixs)
    load('Order_mus_sigmas.mat');
end

muVec = mus{n};
mu = mean(muVec(labels==1)) - mean(muVec(labels==-1));
covMatrix = covMatrixs{n};
covMatrix(labels==0,:) = 0;
covMatrix(:,labels==0) = 0;
covMatrix(labels==1,:) = covMatrix(labels==1,:)/M;
covMatrix(:,labels==1) = covMatrix(:,labels==1)/M;
covMatrix(labels==-1,:) = -covMatrix(labels==-1,:)/N;
covMatrix(:,labels==-1) = -covMatrix(:,labels==-1)/N;
sigma = sqrt(sum(covMatrix(:)));
end