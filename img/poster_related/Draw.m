close all;
clear all;

% [datOrg1,maxImg1] = io.readTiffSeq('D:\AVG_ExVivoSuppRaw (1).tif');
load('mask.mat');
load('Example_dat.mat');
T0 = 30;
[H0,W0] = size(mask);
% im(im>1) = 1;
im(~mask) = 0.3;
im(mask) = 1;
im = imgaussfilt(im,1);
datSel = repmat(im,1,1,T0);
% [H0,W0,T0] = size(datSel);
% sigmaX = 3;
% 
% curve1 = exp(-(1:30-8).^2/2/sigma^2);
% 
%% Synthetic data
% [X,Y,Z]=meshgrid(1:W0,1:H0,1:T0);
% sigma = 4;
% signal = exp(-((Y-50).^2/4+(X-25).^2/4+(Z-25).^2)/2/sigma^2);
% datSel = datSel+signal;
% 
% sigma = 1;
% signal = exp(-((Y-50).^2+(X-35).^2/4+(Z-25).^2)/2/sigma^2);
% datSel = max(datSel,signal);
% 
% sigma = 4;
% signal2 = zeros(size(datSel));
% [X,Y]=meshgrid(1:W0,1:H0);
% line1 = [65:-2.5:55;25*ones(1,5);7:11]';
% line2 = [35:2.5:45;25*ones(1,5);7:11]';
% for t = 1:T0
%     if(t<7)
%         center1 = line1(1,:);
%         center2 = line2(1,:);
%     elseif(t>11)
%         center1 = line1(end,:);
%         center2 = line2(end,:);
%     else
%         center1 = line1(t-6,:);
%         center2 = line2(t-6,:);
%     end
%     signal2(:,:,t) = signal2(:,:,t) + exp(-((Y-center1(1)).^2/4+(X-center1(2)).^2/4+(t-center1(3)).^2)/2/sigma^2);
%     signal2(:,:,t) = max(signal2(:,:,t),exp(-((Y-center2(1)).^2/4+(X-center2(2)).^2/4+(t-center2(3)).^2)/2/sigma^2));
% end
% 
% datSel = datSel+signal2;
% datSel = datSel*1/max(datSel(:));
% 
% msk = single(datSel>0.2);

%% Draw
f = figure;
axRaw = axes(f);
datSel = flipud(datSel);
% datSel = fliplr(datSel);
for ii=1:T0
    % raw data and events
    img0 = 1-datSel(:,:,ii);
%     msk0 = ones(H0,W0);
%     msk0 = msk(:,:,ii);
%     Lx = cat(3,(msk0==2)+(msk0==3),0.5*(msk0==3),msk0==1);
%     imgx = img0+Lx*1;
%     imgx = img0+ones(H0,W0,3)*0.5;
%     alphaMap = (msk0>0)*0.5+0.05;
    
    imgx = cat(3,img0,img0,img0);
    alphaMap = ones(H0,W0)*0.2;
    %%
    [gX,gY,gZ] = meshgrid(1:W0,1:H0,-ii*2);
    s = surf(axRaw,gX,gY,gZ,imgx);hold on
    s.AlphaData = alphaMap;
    s.AlphaDataMapping = 'none';
    s.FaceAlpha = 'flat';
    s.EdgeColor = 'none'; 
end

pbaspect([W0 H0 W0*5])
axRaw.CameraUpVector = [0 1 0];
campos([1158,596 100]);
axis off