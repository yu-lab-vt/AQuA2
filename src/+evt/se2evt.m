function [evtRecon,evtL,dlyMaps,nEvt0,svLabel] = se2evt(...
        dF0,seMap0,seSel,ihw0,rgt,superVoxels,major0,opts)
% ----------- Modified by Xuelong Mi, 02/24/2023 -----------
% GTW on super pixels
% group super pixels to events
[H,W,L,T] = size(dF0);
minTs = 1;
opts.nRoughPixel = 2000;
if numel(ihw0)>30 && T>1
    [dlyMaps,t_scl,minTs,spLst,cx] = evt.spgtw(dF0,seMap0,seSel,superVoxels,major0,opts);
    if(numel(superVoxels)>1)
        [svLabel] = evt.delayMap2evt(dlyMaps{2},major0,opts);
    else
        svLabel = ones(numel(superVoxels),1);
    end
else
    t_scl = 1;
    svLabel = ones(numel(superVoxels),1);
    dlyMaps = cell(3,1);
    for i = 1:3
        dlyMaps{i} = ones(H,W,L);
    end
    spLst = {ihw0};
    dF0Vec = reshape(dF0,[],numel(rgt));
    cx = nanmean(dF0Vec(ihw0,:),1);
    cx = imgaussfilt(cx,2);
    cx = cx - min(cx);
    cx = cx/max(cx);
end

% events
evtL = zeros(size(dF0),'uint16');
for i = 1:numel(superVoxels)
    evtL(superVoxels{i}) = svLabel(i);
end
[evtL,evtRecon] = evt.evtRecon(evtL,seMap0,dF0,seSel,spLst,cx,opts);
nEvt0 = max(svLabel);

% correct delaymap
for i = 1:numel(dlyMaps)
    %                correct temporal downsample      correct coordinate
    dlyMaps{i} = dlyMaps{i}*t_scl + 0.5 - t_scl/2 + minTs - 1 + min(rgt)-1;
end
end

