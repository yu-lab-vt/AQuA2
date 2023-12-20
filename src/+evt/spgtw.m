function [dlyMaps,tempRatio,minTs,spLst,cx] = spgtw(dF,seMap0,seSel,superVoxels,major0,opts)
% ----------- Modified by Xuelong Mi, 07/14/2023 -----------
% spgtw super pixel GTW 
% make one burst to super pixels and run gtw;
[H,W,L,T] = size(dF);
nRoughPixel = opts.nRoughPixel;

% get spatial downsample ratio
[ih,iw,il,it] = ind2sub([H,W,L,T],find(seMap0==seSel));
ihw = unique(sub2ind([H,W,L],ih,iw,il));
spaRatio = max(2,round(sqrt(numel(ihw)/nRoughPixel)));
smoBase = opts.gtwSmo*spaRatio;

% spatial downsample as super pixels
H0 = ceil(H/spaRatio); W0 = ceil(W/spaRatio); L0 = L;
pixDS = unique(sub2ind([H0,W0,L0,T],ceil(ih/spaRatio),ceil(iw/spaRatio),il,it));
mask = false(H0,W0,L0,T);
mask(pixDS) = true;
superPix = find(sum(mask,4));
if size(superPix,2)>1
    superPix = superPix';
end

% only focus on the major time window
mask2 = false(H0*W0*L0,T);
for i = 1:numel(superVoxels)
    [ih0,iw0,il0,it0] = ind2sub([H,W,L,T],superVoxels{i});
    ihw0 = unique(sub2ind([H0,W0,L0],ceil(ih0/spaRatio),ceil(iw0/spaRatio),il0));
    mask2(ihw0,major0{i}.TW) = true;
end
mask2 = reshape(mask2,[H0,W0,L0,T]);

dF = reshape(dF,[],T);
mask0 = reshape(mask&mask2,[],T);
mask = reshape(mask,[],T);
nSp = numel(superPix);
mapping = zeros(H0,W0,L0);
mapping(superPix) = 1:nSp;

spMap = zeros(H,W,L);
[ih,iw,il] = ind2sub([H,W,L],ihw);
spMap(ihw) = mapping(sub2ind([H0,W0,L],ceil(ih/spaRatio),ceil(iw/spaRatio),il));
spLst = label2idx(spMap);

%% GTW prepare
% get curve
tstOrg = zeros(nSp,T);
tst = zeros(nSp,T);
ext = 5; % extension
minTs = T;
tPeaks = zeros(nSp,1);
for k = 1:nSp
    curve = mean(dF(spLst{k},:),1)*sqrt(numel(spLst{k})); % normalize
    curve = imgaussfilt(curve,2);
    TW = find(mask0(superPix(k),:));
    if isempty(TW)
        TW = find(mask(superPix(k),:));
    end

    [maxV,tPeak] = max(curve(TW));
    tPeak = TW(tPeak);
    tPeaks(k) = tPeak;
    
    ts1 = max(min(TW(1)-ext),1);
    [minV,ts] = min(curve(ts1:tPeak));
    ts = ts1 + ts - 1;
    minTs = min(minTs,ts);
    
    curve(1:ts) = minV;
    tstOrg(k,:) = curve;
    curve(tPeak:end) = maxV;
    curve = curve - minV;
    tst(k,:) = curve;
end
maxTPeak = max(tPeaks);
%% temporal downsample
tstOrgCrop = tst(:,minTs:maxTPeak);
T1 = maxTPeak-minTs + 1;
tempRatio = max(1,round(T1/opts.TPatch));   
if T1==1
    dlyMaps = cell(3,1);
    for i = 1:3
        dlyMaps{i} = nan(H,W,L);
        dlyMaps{i}(ihw) = 1;
    end
    cx = zeros(nSp,T);
    cx(:,maxTPeak) = 1;
    return;
end

T0 = ceil(T1/tempRatio);
tst = zeros(nSp,T0);
for t = 1:T0
    t0 = (t-1)*tempRatio+1;
    t1 = min(T1,t*tempRatio);
    tst(:,t) = mean(tstOrgCrop(:,t0:t1),2);
end
tst = tst*sqrt(tempRatio);  %normalize

% reference curve
refBase = 0:1/(T0-1):1; % only align rising part
ref = max(tst,[],2)*refBase;

% get neighbor relation
dh = [-1,0,1,-1,0,1,-1,0,1,1,-1,0,1];
dw = [-1,-1,-1,0,0,0,1,1,1,0,1,1,1];
dl = [1,1,1,1,1,1,1,1,1,0,0,0,0];
Gij = zeros(nSp*13,2);
[ih0,iw0,il0] = ind2sub([H0,W0,L0],superPix);
nPair = 0;
for jj=1:numel(dh)
    ih1 = max(min(H0,ih0+dh(jj)),1);
    iw1 = max(min(W0,iw0+dw(jj)),1);
    il1 = max(min(L0,il0+dl(jj)),1);
    pixShift = sub2ind([H0,W0,L0],ih1,iw1,il1);
    select = ismember(pixShift,superPix);
    Gij(nPair+1:nPair+sum(select),:) = [superPix(select),pixShift(select)];
    nPair = nPair + sum(select);
end
Gij = Gij(1:nPair,:);
Gij = mapping(Gij);
needRemove = Gij(:,1)==Gij(:,2);
Gij = Gij(~needRemove,:);
needSwap = Gij(:,1)>Gij(:,2);
Gij(needSwap,:) = [Gij(needSwap,2),Gij(needSwap,1)];
tmp = unique(sub2ind([nSp,nSp],Gij(:,2),Gij(:,1)));
[col2,col1] = ind2sub([nSp,nSp],tmp);
Gij = [col1,col2];

%% GTW: BILCO calculate matching
distMatrix = zeros(T0,T0,size(tst,1));
for i = 1:nSp
   distMatrix(:,:,i) = (ref(i,:)-tst(i,:)').^2;
end
if(smoBase==0 || isempty(Gij))
    midPoints = zeros(nSp,T0-1);
    for i = 1:nSp
        midPoints(i,:) = DTW_Edge_input(distMatrix(:,:,i));
    end
else
    initialCut0 = DTW_Edge_input(mean(distMatrix,3))+1;
    initialCut = repmat(initialCut0,size(tst,1),1);
    clear distMatrix;
    midPoints = BILCO(ref,tst,Gij,smoBase,initialCut);
end

paths = cell(nSp,1);
for i = 1:nSp
   paths{i} = midPoint2path(midPoints(i,:),T0,T0);
end

%% warping curves
cxAlign = evt.warpRef2Tst(paths,refBase,[H0,W0,L0,T0]);

%% delay time
thrVec = 0.05:0.05:0.95;
tAch = nan(nSp,numel(thrVec));
for nn=1:nSp
    x = cxAlign(nn,:);
    [~,t0] = max(x);
    x = x(1:t0);
    for ii=1:numel(thrVec)
        t1 = find(x>=thrVec(ii),1);
        if isempty(t1)
            t1 = t0;
        end
        tAch(nn,ii) = t1;
    end
end

tDlys = cell(3,1);
% 20% rising time
tDlys{1} = mean(tAch(:,1:7),2);
% 50% rising time
tDlys{2} = mean(tAch,2);
% 80% rising time
tDlys{3} = mean(tAch(:,13:19),2);

dlyMaps = cell(3,1);
mapPix = mapping(sub2ind([H0,W0,L0],ceil(ih/spaRatio),ceil(iw/spaRatio),il));
for i = 1:3
    dlyMaps{i} = nan(H,W,L);
    dlyMaps{i}(ihw) = tDlys{i}(mapPix);
end

% warping back
% obtainde value is the middle point of each downsampled window. Recover it
cxAlignTmpOrg = zeros(nSp,T1);
preMidT = (tempRatio+1)/2;
cxAlignTmpOrg(:,1:floor(preMidT)) = 0 + cxAlign(:,1)/(preMidT-1)*[0:floor(preMidT)-1];
preMidV = cxAlign(:,1);
for t = 2:T0
    t0 = ceil(preMidT);
    tLeft = (t-1)*tempRatio + 1;
    tRight = min(t*tempRatio,T1);
    curMidT = (tLeft + tRight)/2;
    t1 = floor(curMidT);
    cxAlignTmpOrg(:,t0:t1) = preMidV + (cxAlign(:,t) - preMidV)/(curMidT-preMidT) * ([t0:t1] - preMidT);
    preMidV = cxAlign(:,t);
    preMidT = curMidT; 
end
if T1~=preMidT
    cxAlignTmpOrg(:,ceil(preMidT):T1) = preMidV + (1-preMidV)/(T1 - preMidT) * ([ceil(preMidT):T1]-preMidT);
end

cx = zeros(nSp,T);
for k = 1:nSp
    % assign rising part
    x0 = cxAlignTmpOrg(k,:);
    alignedPeak = find(x0==1,1);
    alignedPeak2 = minTs + alignedPeak - 1;
    cx(k,minTs:alignedPeak2) = x0(1:alignedPeak);
    % assign decay part
    % make the first point of x1 has the same intensity of last point of x0
    % scale x1, make it between range(0,1)
    x1 = tstOrg(k,alignedPeak2:end); [minV,id] = min(x1); maxV = tstOrg(k,alignedPeak2);
    x1 = (x1-minV)/(maxV-minV);
    x1(x1>1) = 1;
    x1(id:end) = 0;
    cx(k,alignedPeak2:end) = x1;
end

end