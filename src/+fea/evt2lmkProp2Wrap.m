function [rr,res1] = evt2lmkProp2Wrap(dRecon,evts,lmkLst,muPerPix,minThr)
% evt2lmkProp1Wrap extract propagation direciton related to landmarks
% call evt2lmkProp1 on each data patch

% Xuelong: if I modify, plan to only show min distance and max distance to landmark

[H,W,L,T] = size(dRecon);

thrRg = minThr:0.1:0.9;

% landmarks
nEvts = numel(evts);
nLmk = numel(lmkLst);

% extract blocks
minDistToLandMark = cell(nEvts,nLmk);
maxDistToLandMark = cell(nEvts,nLmk);

for nn=1:numel(evts)
    if mod(nn,100)==0; fprintf('EvtLmk: %d\n',nn); end    
    evt0 = evts{nn};
    if isempty(evt0)
        continue
    end
    
    [h0,w0,l0,t0] = ind2sub([H,W,L,T],evt0);
    for ii=1:nLmk
        [h0k,w0k,l0k] = ind2sub([H,W,L],lmkLst{ii});
        

        rgH = max(min(min(h0), min(h0k))-2,1):min(max(max(h0),max(h0k))+2,H);
        rgW = max(min(min(w0), min(w0k))-2,1):min(max(max(w0),max(w0k))+2,W);
        rgL = max(min(min(l0), min(l0k))-2,1):min(max(max(l0),max(l0k))+2,L);
        rgT = min(t0):max(t0);
        H1 = numel(rgH);
        W1 = numel(rgW);
        L1 = numel(rgL);
        T1 = numel(rgT);
        
        % data
        datS = dRecon(rgH,rgW,rgL,rgT);
        datS = double(datS)/255;
        h0a = h0-rgH(1)+1;
        w0a = w0-rgW(1)+1;
        l0a = l0-rgL(1)+1;
        t0a = t0-rgT(1)+1;
        evt0 = sub2ind([H1,W1,L1,T1],h0a,w0a,l0a,t0a);
        msk = false(size(datS));
        msk(evt0) = true;
        datS = datS.*msk;
    
        % put landmark inside cropped event
        % if some part inside event box, use that part
        % for outside part, stick it to the border
        msk0 = false(H1,W1,L1);
        h1k = h0k - min(rgH) + 1;
        w1k = w0k - min(rgW) + 1;
        l1k = l0k - min(rgL) + 1;
        mskPix = sub2ind(size(msk0),h1k,w1k,l1k);
        msk0(mskPix) = true;
        [minDistLandMark0, maxDistLandMark0] = fea.evt2lmkProp2(datS,msk0,thrRg,muPerPix);
        minDistToLandMark{nn,ii} = minDistLandMark0;
        maxDistToLandMark{nn,ii} = maxDistLandMark0;
    end
end

rr.minDistToLandMark = minDistToLandMark;
rr.maxDistToLandMark = maxDistToLandMark;
end




