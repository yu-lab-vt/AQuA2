function [ov,lblMapS] = regionMapWithData(regionMap,dat,sclOv,reCon,mskx,minSz,minAmp,seedx)
% showActRegion3D draw spatial-temporal FIUs
% use 8 bit for visualization

if ~exist('seedx','var') || isempty(seedx)
    seedx = round(rand()*10000);
end
rng(seedx);

nDimension = numel(size(dat));
dat = uint8(dat*255);
% sclOv = uint8(sclOv);

if ~exist('reCon','var') || isempty(reCon)
    reCon = ones(size(dat));
end

if isa(reCon,'uint8')
    reCon = double(reCon)/255;
end

if ~exist('minSz','var') || isempty(minSz)
    minSz = 0;
end

if ~exist('minAmp','var') || isempty(minAmp)
    minAmp = 0;
end

lblMapS = zeros(size(dat));
if ~iscell(regionMap)
    rPlane = regionMap*0;
    rgPixLst = label2idx(regionMap);
else
    rPlane = zeros(size(dat),'uint8');  
    rgPixLst = regionMap;  
end
N = length(rgPixLst);
if ~exist('mskx','var') || isempty(mskx)
    mskx = ones(1,N);
end
clear regionMap
gPlane = rPlane;
bPlane = rPlane;

for nn=1:N
    if mod(nn,1000)==0; fprintf('%d\n',nn);end
    tmp = rgPixLst{nn};
    if mskx(nn)==0
        continue
    end
    if numel(tmp)<minSz
        continue
    end
    if mean(dat(tmp))<minAmp
        continue
    end
    lblMapS(tmp) = nn;
    x = randi(255,[1,3]);
    while (x(1)>0.8*255 && x(2)>0.8*255 && x(3)>0.8*255) || sum(x)<255
        x = randi(255,[1,3]);
    end
    x = x/max(x)*255;
    rPlane(tmp) = x(1);
    gPlane(tmp) = x(2);
    bPlane(tmp) = x(3);
end

sz = size(dat);
if nDimension == 3 || sz(3) == 1
    rPlane = squeeze(rPlane);
    gPlane = squeeze(gPlane);
    bPlane = squeeze(bPlane);
    reCon = squeeze(reCon);
    dat = squeeze(dat);
    ov = cat(4,uint8(double(rPlane)*sclOv.*reCon) + dat,uint8(double(gPlane)*sclOv.*reCon) + dat,uint8(double(bPlane)*sclOv.*reCon) + dat);
    ov = permute(ov,[1,2,4,3]);
else
    ov = cat(5,uint8(double(rPlane)*sclOv.*reCon) + dat,uint8(double(gPlane)*sclOv.*reCon) + dat,uint8(double(bPlane)*sclOv.*reCon) + dat);
    ov = permute(ov,[1,2,5,3,4]);
end

end




