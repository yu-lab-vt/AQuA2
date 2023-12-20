close all;
clear all;

img = imread('Picture1.png');
% img = rgb2gray(img);
% img = myResize(img,0.2);
cfu = bwconncomp(img>0);
cfu = cfu.PixelIdxList;

img = imread('Picture2.png');
[H0,W0] = size(img);
cc = bwconncomp(img>0);
cc = cc.PixelIdxList;
cfu{5} = cc{1};

T0 = 10;

regionMap = false(H0,W0,5);
for k = 1:numel(cfu)    
    regionMap(cfu{k} + H0*W0*(k-1)) = true;
end
regionMap = se.myResize(regionMap,0.2);
[H0,W0,~] = size(regionMap);
%% Signals
range = [-40,40;-20,30;-40,40;-40,40;-40,40]/5;
f = figure('Position',[100,100,1000,400]);
axRaw = axes(f);
for t = 1:T0
    curIm = zeros(H0,W0);
    for k = 1:numel(cfu)
        if (randi([1,10],1,1)<5)
            alpha = randi([range(k,1),range(k,2)]);
            if (alpha<0)
               curIm = curIm + imerode(regionMap(:,:,k),strel('disk',-alpha)) ;
            else
               curIm = curIm + imdilate(regionMap(:,:,k),strel('disk',alpha)) ;
            end
        end
    end
    curIm(curIm>1) = 1;
    curIm = flipud(curIm);
    arLst = bwconncomp(curIm>0);
    arLst = arLst.PixelIdxList;
    Lx = zeros(H0*W0,3);
    for k = 1:numel(arLst)
        pix = arLst{k};
        x = randi(255,[1,3]);
        while (x(1)>0.8*255 && x(2)>0.8*255 && x(3)>0.8*255) || sum(x)<255
            x = randi(255,[1,3]);
        end
        Lx(pix,1) = x(1)/255;
        Lx(pix,2) = x(2)/255;
        Lx(pix,3) = x(3)/255;
    end
    Lx = reshape(Lx,[H0,W0,3]);
    img0 = 0.3*ones(H0,W0);
    imgx = cat(3,img0,img0,img0)+Lx;
    alphaMap = ones(H0,W0)*0.2 + (curIm)*0.5;
    %%
    [gX,gY,gZ] = meshgrid(1:W0,1:H0,-t*2);
    s = surf(axRaw,gX,gY,gZ,imgx);hold on
    s.AlphaData = alphaMap;
    s.AlphaDataMapping = 'none';
    s.FaceAlpha = 'flat';
    s.EdgeColor = 'none'; 
end
pbaspect([W0 H0 W0*5])
axRaw.CameraUpVector = [0 1 0];
campos([-500,80,-5]);
axis off

