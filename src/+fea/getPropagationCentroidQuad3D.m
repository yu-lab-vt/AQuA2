function ftsPg = getPropagationCentroidQuad3D(volr0,muPerPix,nEvt,ftsPg,opts)
% getFeatures extract local features from events
% specify direction of 'north', or anterior
% not good at tracking complex propagation
% for 3D propagation, Xuelong Mi, 04/05/2023

[H,W,L,T] = size(volr0);

% make coordinate correct
kDi = zeros(6,3);
kDi(1,:) = [0,1,0];  kDi(2,:) = [0,-1,0];
kDi(3,:) = [1,0,0];  kDi(4,:) = [-1,0,0];
kDi(5,:) = [0,0,1];  kDi(6,:) = [0,0,-1];

% propagation features
if isfield(opts,'propthrmin') || ~isnan(opts.propthrmin)
    if opts.propthrmin == opts.propthrmax || opts.propthrstep==0
        thr0 = opts.propthrmin;
    else
        thr0 = opts.propthrmin:opts.propthrstep:opts.propthrmax;
    end
end

nThr = numel(thr0);
volr0(volr0<min(thr0)) = 0;
nPix = sum(volr0(:)>=min(thr0));

% time window for propagation
volr0Vec = reshape(volr0,[],T);
idx0 = find(max(volr0Vec,[],1)>=min(thr0));
t0 = min(idx0);
t1 = max(idx0);

% centroid of earlist frame as starting point
sigt0 = volr0(:,:,:,t0);
loc = find(sigt0>=min(thr0));
[ih,iw,il] = ind2sub([H,W,L],loc);
wt = sigt0(sigt0>=min(thr0));
seedhInit = sum(ih.*wt)/sum(wt);
seedwInit = sum(iw.*wt)/sum(wt);
seedlInit = sum(il.*wt)/sum(wt);

% mask six directions: +X, -X, +Y, -Y, +Z, -Z
msk = false(H,W,L,6);
msk(:,seedwInit:end,:,1) = true;
msk(:,1:seedwInit-1,:,2) = true;
msk(seedhInit:end,:,:,3) = true;
msk(1:seedhInit-1,:,:,4) = true;
msk(:,:,seedlInit:end,5) = true;
msk(:,:,1:seedlInit-1,6) = true;

% locations of centroid
sigDist = nan(T,6,nThr);  % weighted distance for each frame (six directions)
pixNum = zeros(T,nThr);  % pixel number increase
for tt=t0:t1
    imgCur = volr0(:,:,:,tt);
    for kk=1:nThr
        imgCurThr = imgCur>=thr0(kk);
        pixNum(tt,kk) = sum(imgCurThr(:));
        for ii=1:6
            img0 = imgCurThr.*msk(:,:,:,ii);
            loc = find(img0>0);
            [ih,iw,il] = ind2sub([H,W,L],loc);
            seedh = mean(ih);
            seedw = mean(iw);
            seedl = mean(il);
            dh = seedh-seedhInit;
            dw = seedw-seedwInit;    
            dl = seedl-seedlInit;
            sigDist(tt,ii,kk) = [dh,dw,dl]*kDi(ii,:)';
        end      
    end
end

% % max propagation speed.
% boundary = cell(tt,nThr);
% propMaxSpeed = zeros(T,nThr);
% for tt = max(t0-1,1):min(t1+1,T)
%     imgCur = volr0(:,:,:,tt);
%     for kk = 1:nThr
%         BW = imgCur>=thr0(kk);
%         BW = bwperim(BW);
%         boundary{tt,kk} = find(BW);
%     end
% end
% 
% for tt = max(2,t0):t1
%     for kk = 1:nThr
%         [ih0,iw0,il0] = ind2sub([H,W,L],boundary{tt-1,kk});
%         [ih1,iw1,il1] = ind2sub([H,W,L],boundary{tt,kk});
%         if(~isempty(ih0))
%             for ii = 1:numel(ih1)
%                shift = [ih1(ii)-ih0,iw1(ii)-iw0,il1(ii)-il0];
%                dist = sqrt(sum(shift.^2,2));
%                curSpeed = min(dist);
%                propMaxSpeed(tt,kk) = max(propMaxSpeed(tt,kk),curSpeed);
%             end
%         end
%         
%         if(~isempty(ih1))
%             for ii = 1:numel(ih0)
%                shift = [ih0(ii)-ih1,iw0(ii)-iw1,il0(ii)-il1];
%                dist = sqrt(sum(shift.^2,2));
%                curSpeed = min(dist);
%                propMaxSpeed(tt,kk) = max(propMaxSpeed(tt,kk),curSpeed);
%             end
%         end
%     end
% end

prop = nan(size(sigDist));
prop(2:end,:,:) = sigDist(2:end,:,:) - sigDist(1:end-1,:,:);

propGrowMultiThr = prop; 
propGrowMultiThr(propGrowMultiThr<0) = nan; 
propGrow = max(propGrowMultiThr,[],3);
propGrow(isnan(propGrow)) = 0;
propGrowOverall = sum(propGrow,1);

propShrinkMultiThr = prop; 
propShrinkMultiThr(propShrinkMultiThr>0) = nan; 
propShrink = max(propShrinkMultiThr,[],3);
propShrink(isnan(propShrink)) = 0;
propShrinkOverall = sum(propShrink,1);

pixNumChange = zeros(size(pixNum));
pixNumChange(2:end,:) = pixNum(2:end,:)-pixNum(1:end-1,:);
pixNumChangeRateMultiThr = pixNumChange/nPix;
pixNumChangeRateMultiThrAbs = abs(pixNumChangeRateMultiThr);
[~,id] = max(pixNumChangeRateMultiThrAbs,[],2);
pixNumChangeRate = zeros(size(pixNumChangeRateMultiThr,1),1);
for i = 1:size(pixNumChangeRateMultiThr,1)
    pixNumChangeRate(i) = pixNumChangeRateMultiThr(i,id(i));
end

% output
ftsPg.propGrow{nEvt} = propGrow*muPerPix;
ftsPg.propGrowOverall(nEvt,:) = propGrowOverall*muPerPix;
ftsPg.propShrink{nEvt} = propShrink*muPerPix;
ftsPg.propShrinkOverall(nEvt,:) = propShrinkOverall*muPerPix;
ftsPg.areaChange{nEvt} = pixNumChange*muPerPix*muPerPix*muPerPix;
ftsPg.areaChangeRate{nEvt} = pixNumChangeRate;
ftsPg.areaFrame{nEvt} = pixNum*muPerPix*muPerPix*muPerPix;

% ftsPg.propMaxSpeed{nEvt} = propMaxSpeed*muPerPix;
% 
% if numel(thr0)==1
%     ftsPg.maxPropSpeed(nEvt) = max(ftsPg.propMaxSpeed{nEvt});
%     ftsPg.avgPropSpeed(nEvt) = mean(ftsPg.propMaxSpeed{nEvt});
% end
end









