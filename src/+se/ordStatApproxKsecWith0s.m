function [mu, sigma] = ordStatApproxKsecWith0s(fg, bg, nanVec)
% approximate the ~normal distribution using the fg and bg vector
% assuming there is only K parts exist for [0 1]

if isempty(fg) && isempty(bg)
    mu = nan;
    sigma = nan;
    return;
end
fg = double(fg(:));
bg = double(bg(:));
nanVec = double(nanVec(:));
M = length(fg);
N = length(bg);
nanLen = length(nanVec);
n = M+N+nanLen;

delta = 1/n;
all = cat(1, bg, fg, nanVec);
labels = cat(1, bg*0-1, fg*0+1, nanVec*0);
[~, od] = sort(all); % ascending
labels = labels(od);
bkpts = find(labels(2:end)-labels(1:end-1));

ai = cat(1, labels(bkpts), labels(end));
if M>0
    ai(ai>0) = ai(ai>0)*n/M;
end
if N>0
    ai(ai<0) = ai(ai<0)*(n/N);
end

% bi is start, ti is end of the i-th section
bi = cat(1, 0, bkpts*delta);
ti = cat(1, bkpts*delta, 1);

Finvbi = norminv(bi);
Finvbi(1) = -40;
Finvti = norminv(ti);
Finvti(end) = 40;

mu = sum(ai.*(normpdf(Finvbi) - normpdf(Finvti)));
t1=0;
for i=1:length(ai)-1
    aj = ai(i+1:end);
    Finvtj = Finvti(i+1:end);
    Finvbj = Finvbi(i+1:end);
    t1 = t1+ai(i)*...
        sum(aj.*(Finvtj-Finvbj))*...
        (f1(Finvti(i))-f1(Finvbi(i)));
end

t2 = sum(ai.*ai.*Finvti.*(f1(Finvti)-f1(Finvbi)));
t3 = sum(ai.*ai.*(f2(Finvti)-f2(Finvbi)));

A = 2*(t1+t2-t3);
B = (sum(ai.*(f1(Finvti)-f1(Finvbi))))^2;%

sigma = sqrt(A-B)/sqrt(n);

end

function y = f1(x)
    y = x.*normcdf(x)+normpdf(x);
end

function y = f2(x)
    y=0.5*(normcdf(x).*x.^2 - normcdf(x) + normpdf(x).*x);
end
