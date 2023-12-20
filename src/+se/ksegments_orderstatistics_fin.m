function [mu, sigma,k] = ksegments_orderstatistics_fin(largeGroup, smallGroup)

fg = double(largeGroup(:));
bg = double(smallGroup(:));
M = length(fg);
N = length(bg);
n = M+N;

delta = 1/n;
all = cat(1, bg, fg);
labels = cat(1, bg*0-1, fg*0+1);
[~, od] = sort(all); % ascending
labels = labels(od);
bkpts = find(labels(2:end)-labels(1:end-1));
k = numel(bkpts);

J_seg = cat(1, labels(bkpts), -labels(bkpts(end)));
J_seg(J_seg>0) = J_seg(J_seg>0)*n/M;
J_seg(J_seg<0) = J_seg(J_seg<0)*(n/N);

% ai(2:3)=0;
xx = cat(1, 0, bkpts*delta);
yy = cat(1, bkpts*delta, 1);

invxx = norminv(xx);
invxx(1) = -1e5;
invyy = norminv(yy);
invyy(end) = 1e5;

mu = sum(J_seg.*(-normpdf(invyy)+normpdf(invxx)));

A1= 0;
f1invy = f1(invyy);
f1invx = f1(invxx);
for i = 2:(length(xx))
%     A1tmp = sum(J_seg(1:(i-1)).*(f1(invyy(1:(i-1))) - f1(invxx(1:(i-1)))));
    invyyf1J = f1invy(1:(i-1));
    invxxf1J = f1invx(1:(i-1));
    A1 = A1 + sum(J_seg(1:(i-1)).*(invyyf1J - invxxf1J))*J_seg(i)*(invyy(i) - invxx(i));
end
A2 = sum(J_seg.*J_seg.*(f2(invyy) - f2(invxx) +(yy - xx) - (invyy - invxx).*f1invx));
B = sum(J_seg.*(f1invy - f1invx));
S_all = 2*sum(A1+A2) - B^2;
sigma = sqrt(S_all)/sqrt(n);

end
function out = f1(t)
out = t.*normcdf(t) + normpdf(t);
end
function out = f2(t)
out = 1/2*(t.^2.*normcdf(t) - normcdf(t)+t.*normpdf(t));
end