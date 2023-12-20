close all;
clear all;

% [datOrg1,maxImg1] = io.readTiffSeq('D:\AVG_ExVivoSuppRaw (1).tif');
load('mask.mat');
load('Example_dat.mat');
T0 = 30;
[H0,W0] = size(mask);
% im(im>1) = 1;
% im(~mask) = 0.3;
% im(mask) = 1;
% im = imgaussfilt(im,1);
% datSel = repmat(im,1,1,T0);
datSel = zeros(H0,W0,T0);
%% 
for t = 1:T0
    curIm = zeros(H0,W0);
    curIm(mask) = 0.9;%exp(-t/5)/0.9*0.4+0.6;
    curIm(~mask) = 0.3;
    curIm = imgaussfilt(curIm,1);
    datSel(:,:,t) = curIm;
end

%% Draw
f = figure('Position',[100,100,1000,500]);
axRaw = axes(f);
datSel = flipud(datSel);
for ii=1:T0
    % raw data and events
    img0 = 1-datSel(:,:,ii);
    imgx = cat(3,img0,img0,img0);
    alphaMap = ones(H0,W0)*0.2;
    %%
    [gX,gY,gZ] = meshgrid(1:W0,1:H0,-ii*2);
%     if(ii>5)
%         gX = gX + randi([0,10]);
%         gY = gY + randi([0,10]);
%     end
    s = surf(axRaw,gX,gY,gZ,imgx);hold on
    s.AlphaData = alphaMap;
    s.AlphaDataMapping = 'none';
    s.FaceAlpha = 'flat';
    s.EdgeColor = 'none'; 
end

pbaspect([W0 H0 W0*5])
axRaw.CameraUpVector = [0 1 0];
campos([1158,596 52]);
axis off