close all;
clear all;

load('mask.mat');
load('Example_dat.mat');
T0 = 1;
[H0,W0] = size(mask);
datSel = zeros(H0,W0,T0);
%% 
for t = 1:T0
    curIm = zeros(H0,W0);
    curIm(mask) = 0.8;%exp(-t/5)/0.9*0.4+0.6;
    curIm(~mask) = 0.3;
    curIm = imgaussfilt(curIm,1);
    datSel(:,:,t) = curIm;
end

%% Signals
% datSel = datSel + signal;
% datSel = 0.3 + imgaussfilt(signal,1);
%% 
xShift = [zeros(5,1);randi([0,10],15,1)];
yShift = [zeros(5,1);randi([0,10],15,1)];
% xShift = [zeros(20,1);];
% yShift = [zeros(20,1);];
datShow = zeros(H0,W0,T0);
for t = 1:T0
%     rgh = xShift(t)+1:H0;
%     rgw = yShift(t)+1:W0;
    curIm = ones(H0,W0)*0.3;
    curIm(1:end-xShift(t),1:end-yShift(t)) = datSel(xShift(t)+1:H0,yShift(t)+1:W0,t);
    datShow(:,:,t) = curIm;
end

%% Draw
f = figure('Position',[100,100,1000,400]);
axRaw = axes(f);
datShow = flipud(datShow);
for ii=1:T0
    % raw data and events
    img0 = 1-datShow(:,:,ii);
    imgx = cat(3,img0,img0,img0);
    alphaMap = ones(H0,W0)*0.2;
    %%
    [gX,gY,gZ] = meshgrid(1:W0,1:H0,-ii*2);
    gX = gX - yShift(ii);
    gY = gY - xShift(ii);
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