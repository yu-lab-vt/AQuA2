%% load res
% if you export the events, input the path of res file
load('X:\XXX\XXX\res.mat');
% if you click 'Send to workspace' button in AQuA, enable the next line
% res = res_dbg;

%% setting
sclOv = 0.5;    % Color contrast, from 0 to 1

%% average projection
dat = double(res.datOrg);
[H,W,T] = size(dat);
datMean = mean(dat,3);
datMean = datMean-min(datMean(:));
datMean = datMean/max(datMean(:));

%% overlay
evt2D = res.fts.loc.xSpa;
ov0 = res.ov(res.btSt.overlayDatSel);
col = ov0.col;

rPlane = zeros(H,W);
gPlane = zeros(H,W);
bPlane = zeros(H,W);
for nn=1:numel(evt2D)
    tmp = evt2D{nn};
    x = col(nn,:);
    rPlane(tmp) = x(1);
    gPlane(tmp) = x(2);
    bPlane(tmp) = x(3);
end

ov1 = zeros(H,W,3,'uint8');
ov1(:,:,1) = uint8(double(rPlane)*sclOv*255) + uint8(datMean*255);
ov1(:,:,2) = uint8(double(gPlane)*sclOv*255) + uint8(datMean*255);
ov1(:,:,3) = uint8(double(bPlane)*sclOv*255) + uint8(datMean*255);
figure;imagesc(ov1);