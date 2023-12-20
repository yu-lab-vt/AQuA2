function [evtL,evtRecon] = evtRecon(evtL,seMap0,dF0,seSel,spLst,cx,opts)
% created by Xuelong 02/28/2023
[H,W,L,T] = size(seMap0);
evtRecon = zeros(H*W*L,T);

% downsample
nSp = numel(spLst);
whetherExtend = opts.whetherExtend;

% overlay brightness
for k = 1:nSp
    sp0 = spLst{k};
    x0 = cx(k,:);
    evtRecon(sp0,:) = repmat(x0,numel(sp0),1);
end

if whetherExtend
    spMap = zeros(H,W,L);
    for i = 1:nSp
        spMap(spLst{i}) = i;
    end

    % extend
    evtLst = label2idx(evtL);
    dF0 = imgaussfilt(dF0,2);
    dF0Vec = reshape(dF0,[],T);
    seMap0 = reshape(seMap0,[],T);
    evtL = reshape(evtL,[],T);
    for ii=1:numel(evtLst)
        pix = evtLst{ii};
        [ih,iw,il,~] = ind2sub([H,W,L,T],pix);
        curEvtIhw = unique(sub2ind([H,W,L],ih,iw,il));
        spLabels = setdiff(spMap(curEvtIhw),0);
        evtL0 = evtL==ii;
        for k = 1:numel(spLabels)
            curSp = spLst{(spLabels(k))};
            curSp = intersect(curSp,curEvtIhw);
            x0 = mean(dF0Vec(curSp,:),1);

            curTemporal = sum(evtL0(curSp,:),1);
            t0 = find(curTemporal>0,1);
            t1 = find(curTemporal>0,1,'last');
            [maxV,tPeak] = max(x0(t0:t1));
            tPeak = tPeak + t0 - 1;
            ts = find(x0(1:tPeak)<maxV*opts.minShow1,1,'last') + 1;
            if isempty(ts)
                ts = 1;
            end
            te = find(x0(tPeak:end)<maxV*opts.minShow1,1) + tPeak - 2;
            if isempty(te)
                te = T;
            end

            % update evtL and evtRecon
            avaliable = seMap0(curSp,ts:te)==0 & evtL(curSp,ts:te)==0;
            curEvtL = evtL(curSp,ts:te);
            curEvtL(avaliable) = ii;
            evtL(curSp,ts:te) = curEvtL;
            curEvtL = seMap0(curSp,ts:te);
            curEvtL(avaliable) = seSel;
            seMap0(curSp,ts:te) = curEvtL;
        end
    end
    evtL = reshape(evtL,H,W,L,T);
    seMap0 = reshape(seMap0,H,W,L,T);
end

evtRecon = reshape(evtRecon,H,W,L,T);
evtRecon(seMap0~=seSel) = 0;
end
