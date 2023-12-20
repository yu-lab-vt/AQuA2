close all;
clear all;

% [datOrg1,maxImg1] = io.readTiffSeq('D:\AVG_ExVivoSuppRaw (1).tif');
load('mask.mat');
load('Example_dat.mat');
T0 = 20;
[H0,W0] = size(mask);
datSel = zeros(H0,W0,T0);
%% 
for t = 1:T0
    curIm = zeros(H0,W0);
    curIm(mask) = 0.6;%exp(-t/5)/0.9*0.4+0.6;
    curIm(~mask) = 0.3;
%     curIm = imgaussfilt(curIm,1);
    datSel(:,:,t) = curIm;
end

%% Signals
points = ...
[22,22,1,0.2;
39,21,1,0.2;
75,55,1,0.3;
22,22,2,0.4;
39,21,2,0.4;
75,55,2,0.6;
22,22,3,0.6;
39,21,3,0.6;
75,55,3,0.9;
22,22,4,0.9;
39,21,4,0.9;
27,27,5,0.8;
75,55,4,1.0;
63,58,4,1.0;
30,33,5,1.0;
59,59,5,1.0;
27,42,6,0.5;
53,59,6,1.0;
28,48,7,0.4;
45,59,7,1.0;
26,67,7,0.5;
28,53,8,1.0;
% 32,59,8,1.0;
26,67,8,1.0;
28,53,9,0.7;
26,67,9,0.7;
28,53,10,0.5;
26,67,10,0.5;
28,53,11,0.3;
26,67,11,0.3;
28,53,12,0.1;
26,67,12,0.1;
28,53,13,0.1;
28,53,14,0.3;
28,53,15,0.5;
28,53,16,0.8;
28,53,17,1;
28,53,18,0.8;
28,53,19,0.6;
28,53,20,0.3;
];

signal = zeros(H0,W0,T0);
for i = 1:size(points,1)
    centerX = points(i,1);
    centerY = points(i,2);
    t = points(i,3);
    strength = points(i,4);
    [X,Y]=meshgrid(1:W0,1:H0);
    sigma = 8;
    if(centerX==26) sigma = 3;end
    curIm = exp(-((Y-centerX).^2+(X-centerY).^2)/2/sigma^2);
    signal(:,:,t) =  signal(:,:,t) + curIm*strength;
end
for t = 1:T0
    curIm = signal(:,:,t);
    curIm(~mask) = 0;
    signal(:,:,t) = imgaussfilt(curIm,1);
    datSel(:,:,t) = imgaussfilt(datSel(:,:,t)+curIm,1);
end
datSel = 0.3+signal;

%% active region
sdLst = bwconncomp(signal>0.5);
sdLst = sdLst.PixelIdxList;
% zzshow(ac);
labelMap = zeros(H0,W0,T0);
for i = 1:numel(sdLst)
    labelMap(sdLst{i}) = i;
end

col = [247,92,47;134,193,102;51,166,184;251,226,81]/255;

%% 
% xShift = [zeros(5,1);randi([0,2],15,1)];
% yShift = [zeros(5,1);randi([0,8],15,1)];
xShift = [zeros(20,1);];
yShift = [zeros(20,1);];
datShow = zeros(H0,W0,T0);
for t = 1:T0
    curIm = ones(H0,W0)*0.3;
    curIm(1:end-xShift(t),1:end-yShift(t)) = datSel(xShift(t)+1:H0,yShift(t)+1:W0,t);
    datShow(:,:,t) = curIm;
end

%% Draw
f = figure('Position',[100,100,1000,400]);
axRaw = axes(f);
datShow = flipud(datShow);
labelMap = flipud(labelMap);
for ii=1:T0
    % raw data and events
    img0 = datShow(:,:,ii);
    
    Lx = zeros(H0*W0,3);
    for k = 1:numel(sdLst)
       pix = find(labelMap(:,:,ii)==k);
       Lx(pix,1) = col(k,1);
       Lx(pix,2) = col(k,2);
       Lx(pix,3) = col(k,3);
    end
    Lx = reshape(Lx,[H0,W0,3]);
    img0(labelMap(:,:,ii)>0) = img0(labelMap(:,:,ii)>0)*0.3;
    imgx = cat(3,img0,img0,img0)+Lx;
    alphaMap = 0.2 + (labelMap(:,:,ii)>0)*0.8;
    %%
    [gX,gY,gZ] = meshgrid(1:W0,1:H0,-ii*2);
    gX = gX + yShift(ii);
    gY = gY + xShift(ii);
    s = surf(axRaw,gX,gY,gZ,imgx);hold on
    s.AlphaData = alphaMap;
    s.AlphaDataMapping = 'none';
    s.FaceAlpha = 'flat';
    s.EdgeColor = 'none'; 
end

pbaspect([W0 H0 W0*5])
axRaw.CameraUpVector = [0 1 0];
campos([2000,596 52]);
axis off