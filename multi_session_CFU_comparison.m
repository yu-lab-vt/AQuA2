% Read Me:
% This script is used to compare the CFUs of two different 2D datasets with the same dimension.
% Will display:
% CFUs of session 1
% CFUs of session 2
% CFUs of both sessions (yellow)
% CFUs only in session 1 (blue) and CFUs only in session 2 (orange)
clear;
clc;
startup;

%% setting
p1 = 'F:\AQuA_prepare_data\K53_results\K53_firstpart\K53_firstpart_AQuA2_res_cfu.mat';
p2 = 'F:\AQuA_prepare_data\K53_results\K53_lastpart\K53_lastpart_AQuA2_res_cfu.mat';
overlap = 0.4;  % how large IoU be considered as the same CFU

%% load
session1 = load(p1);
session2 = load(p2);

%%
[H, W] = size(session1.datPro);
cfu1 = session1.cfuInfo1;
cfu2 = session2.cfuInfo1;
nCFU1 = size(cfu1, 1);
nCFU2 = size(cfu2, 1);
regionThr = 0.1;


%%
cfuMap1 = false(H, W, nCFU1);
cfuMap2 = false(H, W, nCFU2);

for i = 1:nCFU1
    cfuMap1(:, :, i) = cfu1{i, 3} > regionThr;
end
for i = 1:nCFU2
    cfuMap2(:, :, i) = cfu2{i, 3} > regionThr;
end

%% Pair
pairs1 = zeros(nCFU1, 2);
pairs2 = zeros(nCFU2, 2);


cfuMapCheck2 = reshape(cfuMap2, [], nCFU2);
for i = 1:nCFU1
    id1 = i;
    pix = find(cfu1{id1, 3} > regionThr);
    candidates = find(sum(cfuMapCheck2(pix, :),1));
    IoUs = zeros(1, numel(candidates));
    for j = 1:numel(candidates)
        id2 = candidates(j);
        pix2 = find(cfu2{id2, 3} > regionThr);
        pixIn = intersect(pix, pix2);
        pixUnion = union(pix, pix2);
        IoUs(j) = numel(pixIn) / numel(pixUnion);
    end
    [IoU, id2] = max(IoUs);
    id2 = candidates(id2);
    if IoU > overlap
        pairs1(id1,:) = [id2, IoU];
        pairs2(id2,:) = [id1, IoU];
    end 
end

%%
common = cell(0,1);
only1 = cell(0,1);
only2 = cell(0,1);
for i = 1:nCFU1
    if pairs1(i, 1) > 0
        id1 = i;
        id2 = pairs1(i);
        common{numel(common) + 1, 1} = (cfu1{id1, 3} + cfu2{id2, 3}) / 2;
    else
        only1{numel(only1) + 1, 1} = cfu1{i, 3};
    end
end
for i = 1:nCFU2
    if pairs2(i, 1) == 0
        only2{numel(only2) + 1, 1} = cfu2{i, 3};
    end
end

%%
datPro = rescale(session1.datMedian);
ov = cat(3, datPro, datPro, datPro);
for i = 1:nCFU1
    x = randi(255,[1,3]);
    while (x(1)>0.8*255 && x(2)>0.8*255 && x(3)>0.8*255) || sum(x)<255
        x = randi(255,[1,3]);
    end
    ov(:, :, 1) = ov(:, :, 1) + 0.8 * x(1) / 255 * cfu1{i,3};
    ov(:, :, 2) = ov(:, :, 2) + 0.8 * x(2) / 255 * cfu1{i,3};
    ov(:, :, 3) = ov(:, :, 3) + 0.8 * x(3) / 255 * cfu1{i,3};
end
figure;
imshow(ov)

datPro = rescale(session2.datMedian);
ov = cat(3, datPro, datPro, datPro);
for i = 1:nCFU2
    x = randi(255,[1,3]);
    while (x(1)>0.8*255 && x(2)>0.8*255 && x(3)>0.8*255) || sum(x)<255
        x = randi(255,[1,3]);
    end
    ov(:, :, 1) = ov(:, :, 1) + 0.8 * x(1) / 255 * cfu2{i,3};
    ov(:, :, 2) = ov(:, :, 2) + 0.8 * x(2) / 255 * cfu2{i,3};
    ov(:, :, 3) = ov(:, :, 3) + 0.8 * x(3) / 255 * cfu2{i,3};
end
figure;
imshow(ov)



%%
datPro = rescale(session1.datMedian);
ov = cat(3, datPro, datPro, datPro);
for i = 1:numel(common)
    ov(:, :, 1) = ov(:, :, 1) + 0.6 * 1 * common{i};
    ov(:, :, 2) = ov(:, :, 2) + 0.6 * 0.75 * common{i};
end
figure;
imshow(ov)

ov = cat(3, datPro, datPro, datPro);
for i = 1:numel(only1)
    ov(:, :, 1) = ov(:, :, 1) + 0.6 * 68 / 255 * only1{i};
    ov(:, :, 2) = ov(:, :, 2) + 0.6 * 114 / 255 * only1{i};
    ov(:, :, 3) = ov(:, :, 3) + 0.6 * 196 / 255 * only1{i};
end
for i = 1:numel(only2)
    ov(:, :, 1) = ov(:, :, 1) + 0.6 * 217 / 255 * only2{i};
    ov(:, :, 2) = ov(:, :, 2) + 0.6 * 83 / 255 * only2{i};
    ov(:, :, 3) = ov(:, :, 3) + 0.6 * 25 / 255 * only2{i};
end
figure;
imshow(ov)

% %%
% [~, ids] = sort(pairs1(:,2),'descend');
% for i = 1:5
%     id1 = ids(i);
%     id2 = pairs1(id1, 1);
%     map = (cfu1{id1, 3} + cfu2{id2, 3}) / 2;
%     curve1 = rescale(cfu1{id1, 5});
%     curve2 = rescale(cfu2{id2, 5});
%     figure('Position', [100,100,400, 200]);
%     plot(curve1);
%     hold on ;
%     plot(curve2 - 0.5);
%     axis off;
%     keyboard;
% end