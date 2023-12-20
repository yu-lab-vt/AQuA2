function rLmk = evt2lmkProp(evts,lmkBorder,sz,muPerPix)
% distances and directions between events and landmarks
% Modified by Xuelong, 04/02/2023 => 3D version

nEvt = numel(evts);
nLmk = numel(lmkBorder);

% distance to landmark
d2lmk = cell(nEvt,1);
d2lmkMax = cell(nEvt,1);
d2lmkAvg = nan(nEvt,nLmk);
d2lmkMin = nan(nEvt,nLmk);

% propagation direction toward or away from landmark
% fprintf('Calculating distances to landmarks ...\n')
for ii=1:length(evts)
    if mod(ii,100)==0
        fprintf('lmkDist: %d\n',ii)
    end
    loc0 = evts{ii};
    if isempty(loc0)
        continue
    end
    [ih,iw,il,it] = ind2sub(sz,loc0);
    tRg = min(it):max(it);
    distPix = nan(numel(tRg),nLmk);
    distPixMax = nan(numel(tRg),nLmk);
    
    for tt=1:numel(tRg)
        ixSel = it==tRg(tt);
        if sum(ixSel)==0
            continue
        end
        ih0 = ih(ixSel);
        iw0 = iw(ixSel);
        il0 = il(ixSel);
        
        for jj=1:nLmk
            cc = lmkBorder{jj};
            dist = sqrt((ih0'-cc(:,1)).^2 + (iw0'-cc(:,2)).^2 + (il0'-cc(:,3)).^2);
            distPix(tt,jj) = min(dist(:));
            distPixMax(tt,jj) = min(max(dist,[],2));
        end
    end
    
    % cleaning - but suppose there is no nan value
    for tt=1:size(distPix,1)
        for jj=1:nLmk
            if isnan(distPix(tt,jj))
                if tt>1
                    distPix(tt,jj) = distPix(tt-1,jj);
                    distPixMax(tt,jj) = distPixMax(tt-1,jj);
                end
            end
        end
    end
    
    % distance to landmark
    d2lmk{ii} = distPix*muPerPix;  % shortest distance to landmark at each frame
    d2lmkMax{ii} = distPixMax*muPerPix;
    d2lmkAvg(ii,:) = mean(distPix,1,'omitnan')*muPerPix;  % average distance to the landmark
    d2lmkMin(ii,:) = min(distPix,[],1)*muPerPix;  % minimum distance to the landmark
end

rLmk = [];
rLmk.distPerFrame = d2lmk;
rLmk.distMaxPerFrame = d2lmkMax;
rLmk.distAvg = d2lmkAvg;
rLmk.distMin = d2lmkMin;

end







