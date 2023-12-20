function [actReg3,evtMap] = regionMapWithData_newColor(evtLst,dat,sclOv,reCon)
% showActRegion3D draw spatial-temporal FIUs
% use 8 bit for visualization

if ~exist('seedx','var') || isempty(seedx)
    seedx = round(rand()*10000);
end
rng(seedx);

[H,W,T] = size(dat);
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

evtMap = zeros(H,W,T);
N = numel(evtLst);
for i = 1:N
    evtMap(evtLst{i}) = i;
end
% get neighbor
neiLst = cell(N,1);
[dw,dh,dt] = se.dirGenerate(26);

for i = 1:N
    pix = evtLst{i};
    [ih0,iw0,it0] = ind2sub([H,W,T],pix);
    neib0 = [];
    for k = 1:numel(dw)
        ih = max(1,min(H,ih0+dh(k)));
        iw = max(1,min(W,iw0+dw(k)));
        it = max(1,min(T,it0+dt(k)));
        pix_c = sub2ind([H,W,T],ih,iw,it);
       neib0 = union(neib0,setdiff(evtMap(pix_c),[0,i]));
    end
    neiLst{i} = neib0;
end
% assign color
load('colId.mat');
[cr,cg,cb] = ind2sub([255,255,255],colId);
colAssign = false(N,1);
colEvt = zeros(N,3);
rPlane = zeros(size(dat),'uint8');
gPlane = rPlane;
bPlane = rPlane;
for i = 1:N
    if mod(i,1000)==0; fprintf('%d\n',i);end
    neib0 = neiLst{i};
    neib0 = neib0(colAssign(neib0));
    if(isempty(neib0))
        id = randi(numel(colId),1);
        colEvt(i,1) = cr(id);
        colEvt(i,2) = cg(id);
        colEvt(i,3) = cb(id);
    else
       distCol = inf(numel(colId),1);
       for k = 1:numel(neib0)
           curL = neib0(k);
           rr = colEvt(curL,1);
           gg = colEvt(curL,2);
           bb = colEvt(curL,3);
           rBar = (cr + rr)/2;
           curDist = (2 + rBar/256).*(cr-rr).^2 + 4*(cg - gg).^2 + (3 - rBar/256).*(cb - bb).^2;
           distCol = min(distCol,sqrt(curDist));
       end
       ids = find(distCol>min(200,max(distCol)*0.8));
       id = ids(randi(numel(ids),1));
%        [~,id] = max(distCol);
    end
   colEvt(i,1) = cr(id);
   colEvt(i,2) = cg(id);
   colEvt(i,3) = cb(id);
   colAssign(i) = true;
   pix = evtLst{i};
   rPlane(pix) = colEvt(i,1);
   gPlane(pix) = colEvt(i,2);
   bPlane(pix) = colEvt(i,3);
end

actReg3 = zeros(H,W,3,T,'uint8');
actReg3(:,:,1,:) = uint8(double(rPlane)*sclOv.*reCon) + dat;
actReg3(:,:,2,:) = uint8(double(gPlane)*sclOv.*reCon) + dat;
actReg3(:,:,3,:) = uint8(double(bPlane)*sclOv.*reCon) + dat;

end




