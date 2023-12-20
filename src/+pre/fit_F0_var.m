function [varMapOut] = fit_F0_var(F0ProOrg,varMapOrg,validMap)
% --- Piecewise linear function to model variance vs. F0 ---
% 3-segment inclined segments + 2-segment horizontal segments
% 02/01/2023, Xuelong

%% preprocess
if exist('validMap','var')
    % remove boundary pixels
    varMapOrg(~validMap) = nan;
end

% reason: remove the values close to 0, which is not correct
F0Pro = F0ProOrg(varMapOrg>1e-8);
varMap = varMapOrg(varMapOrg>1e-8);
% figure;scatter(F0Pro(:),varMap(:));xlabel('F_0');ylabel('var');

if isempty(F0Pro)
    % if no valid variance
    varMapOut = ones(size(F0ProOrg)) * 1e-8;
    return;
end

%% downsample
% reason: the number of original pixels is too large. Hard to compute, and
% won't contribute much to the final results.
% [F0Pro,id] = sort(F0Pro);
% varMap = varMap(id);
minX = min(F0Pro);
maxX = max(F0Pro);
delta = max(1e-5,(maxX-minX)/2000); % 2000, just one assigned parameter

x = zeros(2000,1);
y = zeros(2000,1);
valid = false(2000,1);
parfor i = 1:2000
    if i==1
        select = F0Pro>=minX+(i-1)*delta  & F0Pro<=minX+i*delta;
    else
        select = F0Pro>minX+(i-1)*delta  & F0Pro<=minX+i*delta;
    end
    if sum(select)>0
        x(i) = mean(F0Pro(select));
        y(i) = mean(varMap(select));
        valid(i) = true;
    end
end
x = x(valid);
y = y(valid);

if numel(x)==1
    varMapOut = ones(size(F0ProOrg)) * y(1);
    return;
end
% figure;scatter(x(:),y(:));xlabel('F_0');ylabel('var');

%% graph construction
% the start point and end point, if pick the most extreme ones, too
% unstable. Since source is more dense, we could use more points.

source = ceil(numel(y)*0.05);
sink = max(1,floor(numel(y)*0.99));
% first layer
dist1 = inf(numel(y),1);
preMap1 = zeros(numel(y),1);
parfor j = 1:numel(y)
    minCost = inf;
    preNode = j;
    for i = 1:min(j-1,source)
        a = (y(j) - y(i))/(x(j) - x(i));
        b = y(i) - a*x(i);
        % first term => first inclined segment
        % second term => horizontal segment
        cost = sum(abs(y(i:j) - (a*x(i:j)+b))) + sum(abs(y(1:i)-y(i)));
        if cost<minCost
            minCost = cost;
            preNode = i;
        end
        dist1(j) = minCost;
        preMap1(j) = preNode;
    end
end

% second layer
dist2 = inf(numel(y),1);
preMap2 = zeros(numel(y),1);
parfor j = 1:numel(y)
    minCost = inf;
    preNode = j;
    for i = 1:j-1
        a = (y(j) - y(i))/(x(j) - x(i));
        b = y(i) - a*x(i);
        cost = sum(abs(y(i:j) - (a*x(i:j)+b)));
        if dist1(i) + cost<minCost
            minCost = dist1(i) + cost;
            preNode = i;
        end
    end
    dist2(j) = minCost;
    preMap2(j) = preNode;
end

% third layer
dist3 = inf(numel(y),1);
preMap3 = zeros(numel(y),1);
parfor j = sink:numel(y)
    minCost = inf;
    preNode = j;
    for i = 1:j-1
        a = (y(j) - y(i))/(x(j) - x(i));
        b = y(i) - a*x(i);
        % first term => last inclined segment
        % second term => horizontal segment
        cost = sum(abs(y(i:j) - (a*x(i:j)+b))) + sum(abs(y(j:end) - y(j)));
        if dist2(i) + cost<minCost
            minCost = dist2(i) + cost;
            preNode = i;
        end
    end
    dist3(j) = minCost;
    preMap3(j) = preNode;
end
[~,node3] = min(dist3); %-> sink
x3 = x(node3);
y3 = y(node3);

node2 = preMap3(node3); % -> end of 2nd segment
x2 = x(node2);
y2 = y(node2);

node1 = preMap2(node2); % -> end of 1st segment
x1 = x(node1);
y1 = y(node1);

node0 = preMap1(node1); % -> start of 1st segment
x0 = x(node0);
y0 = y(node0);

a1 = (y0 - y1)/(x0 - x1);
b1 = y1 - a1*x1;

a2 = (y1 - y2)/(x1 - x2);
b2 = y2 - a2*x2;

a3 = (y3 - y2)/(x3 - x2);
b3 = y3 - a3*x3;

%% fitting
varMapOut = varMapOrg;
% in case negative variance based on obtained piecewise linear function
varMapOut(F0ProOrg<=x0) = y0;
select = F0ProOrg>=x0 & F0ProOrg<x1;
varMapOut(select) = a1*F0ProOrg(select)+b1;
select = F0ProOrg>=x1 & F0ProOrg<x2;
varMapOut(select) = a2*F0ProOrg(select)+b2;
select = F0ProOrg>=x2 & F0ProOrg<=x3;
varMapOut(select) = a3*F0ProOrg(select)+b3;
varMapOut(F0ProOrg>=x3) = y3;

% in case negative variance based on obtained piecewise linear function
varMapOut(isnan(varMapOut)) = y0;


% % check fitting
% figure('Position',[100,50,550,950]);
% subplot(2,1,1);
% scatter(F0ProOrg(:),varMapOrg(:));xlabel('F_0');ylabel('var');
% hold on;
% plot([min(x),x0,x1,x2,x3,max(x)],[y0,y0,y1,y2,y3,y3],'r');
% subplot(2,1,2);
% imagesc(varMapOut);colorbar;

end