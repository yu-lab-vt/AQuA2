function [dff1,rgT1] = extendEventTimeRangeByCurve(dff,sigxOthers,rgT)

T = numel(dff);
t0 = min(rgT);
t1 = max(rgT);

% begin and end of nearest others
i0 = find(sigxOthers(1:t0)>0,1,'last');
if isempty(i0)
    i0 = 1;
end

i1 = find(sigxOthers(t1:T)>0,1);
if isempty(i1)
    i1 = T;
else
    i1 = i1+t1-1;
end

% minimum point
[~,ix] = min(dff(i0:t0));
t0a = i0+ix-1;

[~,ix] = min(dff(t1:i1));
t1a = t1+ix-1;

dff1 = dff(t0a:t1a);
rgT1 = t0a:t1a;
end