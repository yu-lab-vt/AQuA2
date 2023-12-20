function ftsPg = getPropagationCentroidQuad(volr0,muPerPix,nEvt,ftsPg,northDi,opts)
% getFeatures extract local features from events
% specify direction of 'north', or anterior
% not good at tracking complex propagation

[H,W,L,T] = size(volr0);

% make coordinate correct
volr0 = permute(volr0,[1,2,4,3]);
volr0 = volr0(end:-1:1,:,:);

a = northDi(1);
b = northDi(2);
kDi = zeros(4,2);
kDi(1,:) = [a,b];
kDi(2,:) = [-a,-b];
kDi(3,:) = [-b,a];
kDi(4,:) = [b,-a];

singleThr = 0;
% propagation features
if isfield(opts,'propthrmin') || ~isnan(opts.propthrmin)
    if opts.propthrmin == opts.propthrmax || opts.propthrstep==0
        thr0 = opts.propthrmin;
        singleThr = 1;
    else
        thr0 = opts.propthrmin:opts.propthrstep:opts.propthrmax;
    end
end

nThr = numel(thr0);
volr0(volr0<min(thr0)) = 0;
sigMap = sum(volr0>=min(thr0),3);
nPix = sum(sigMap(:)>0);

% time window for propagation
volr0Vec = reshape(volr0,[],T);
idx0 = find(max(volr0Vec,[],1)>=min(thr0));
t0 = min(idx0);
t1 = max(idx0);

% centroid of earlist frame as starting point
sigt0 = volr0(:,:,t0);
[ih,iw] = find(sigt0>=min(thr0));
wt = sigt0(sigt0>=min(thr0));
seedhInit = sum(ih.*wt)/sum(wt);
seedwInit = sum(iw.*wt)/sum(wt);
h0 = max(round(seedhInit),1);
w0 = max(round(seedwInit),1);

% mask four directions: north, south, west, east
msk = zeros(H,W,4);
for ii=1:4
    [y,x] = find(ones(H,W));    
    switch ii
        case 1
            ixSel = y>-a/b*(x-w0)+h0;
        case 2
            ixSel = y<-a/b*(x-w0)+h0;
        case 3
            ixSel = y>b/a*(x-w0)+h0;
        case 4
            ixSel = y<b/a*(x-w0)+h0;
    end
    msk0 = zeros(H,W);
    msk0(sub2ind([H,W],y(ixSel),x(ixSel))) = 1;
    msk(:,:,ii) = msk0;    
end

% locations of centroid
sigDist = nan(T,4,nThr);  % weighted distance for each frame (four directions)
pixNum = zeros(T,nThr);  % pixel number increase
for tt=t0:t1
    imgCur = volr0(:,:,tt);
    for kk=1:nThr
        imgCurThr = imgCur>=thr0(kk);
        pixNum(tt,kk) = sum(imgCurThr(:));
        for ii=1:4            
            img0 = imgCurThr.*msk(:,:,ii);
            [ih,iw] = find(img0>0);
            if numel(ih)<4
                continue
            end
            seedh = mean(ih);
            seedw = mean(iw);
            dh = seedh-seedhInit;
            dw = seedw-seedwInit;            
            sigDist(tt,ii,kk) = sum([dw,dh].*[kDi(ii,1),kDi(ii,2)]);
        end      
    end
end


% max propagation speed.
% boundary = cell(tt,nThr);
% propMaxSpeed = zeros(T,nThr);
% for tt = max(t0-1,1):min(t1+1,T)
%     imgCur = volr0(:,:,tt);
%     for kk = 1:nThr
%         pixCur = imgCur>=thr0(kk);
%         pixCur = bwmorph(pixCur,'close');
%         boundary{tt,kk} = cell2mat(bwboundaries(pixCur));
%     end
% end
% 
% for tt = max(2,t0):t1
%     for kk = 1:nThr
%         preBound = boundary{tt-1,kk};
%         curBound = boundary{tt,kk};
%         if(~isempty(preBound))
%             for ii = 1:size(curBound,1)
%                xy = curBound(ii,:);
%                shift = xy-preBound;
%                dist = sqrt(shift(:,1).^2 + shift(:,2).^2);
%                curSpeed = min(dist);
%                propMaxSpeed(tt,kk) = max(propMaxSpeed(tt,kk),curSpeed);
%             end
%         end
%         
%         if(~isempty(curBound))
%             for ii = 1:size(preBound,1)
%                xy = preBound(ii,:);
%                shift = xy-curBound;
%                dist = sqrt(shift(:,1).^2 + shift(:,2).^2);
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
ftsPg.areaChange{nEvt} = pixNumChange*muPerPix*muPerPix;
ftsPg.areaChangeRate{nEvt} = pixNumChangeRate;

ftsPg.areaFrame{nEvt} = pixNum*muPerPix*muPerPix;
% ftsPg.propMaxSpeed{nEvt} = propMaxSpeed*muPerPix;
% 
% if singleThr
%     ftsPg.maxPropSpeed(nEvt) = max(ftsPg.propMaxSpeed{nEvt});
%     ftsPg.avgPropSpeed(nEvt) = mean(ftsPg.propMaxSpeed{nEvt});
% end

end









