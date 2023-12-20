function res = getEvtNetworkFeatures(evts,sz)
% getEvtNetworkFeatures get network work level features for each event
% Not include evnet level features like size and brightness
% Pre-filter with bounding box overlapping
% Rewritten by Xuelong Mi, 04/05/2023

H = sz(1); W = sz(2); L= sz(3); T = sz(4);

nEvt = numel(evts);
evtSize = zeros(nEvt,1);
idxBad = true(nEvt,1);
tIdx = cell(T,1);
evtMap = zeros(sz,'uint16');
evtIhw = cell(nEvt,1);
evtTW = nan(nEvt,2);
for nn=1:nEvt
    pix0 = evts{nn};
    if ~isempty(pix0)
        evtMap(pix0) = nn;
        idxBad(nn) = false;
        [ih,iw,il,it] = ind2sub([H,W,L,T],pix0);
        ihw = sub2ind([H,W,L],ih,iw,il);
        ihw = unique(ihw);
        evtIhw{nn} = ihw;
        evtSize(nn) = numel(ihw);
        evtTW(nn,:) = [min(it),max(it)];
    end
end
evtMap = reshape(evtMap,[],T);
for t = 1:T
    tIdx{t} = setdiff(evtMap(:,t),0);
end

% all events and events with similar size
nOccurSameLoc = nan(nEvt,2);
nOccurSameTime = nan(nEvt,1);
occurSameLocList = cell(nEvt,2);
occurSameTimeList = cell(nEvt,1);
for ii=1:nEvt
    if mod(ii,1000)==0
        fprintf('%d\n',ii);
    end    
    if idxBad(ii)
        continue
    end
    ihw = evtIhw{ii};
    lst = setdiff(evtMap(ihw,:),0);
    occurSameLocList{ii,1} = lst;
    nOccurSameLoc(ii,1) = numel(lst);
    szCo = evtSize(lst);
    szMe = evtSize(ii);
    isSelSimilarSize = szMe./szCo<2 & szMe./szCo>1/2;
    occurSameLocList{ii,2} = lst(isSelSimilarSize);
    nOccurSameLoc(ii,2) = sum(isSelSimilarSize);

    % occur at same time
    t0 = evtTW(ii,1); t1 = evtTW(ii,2);
    lst = [];
    for t = t0:t1
        lst = union(lst,tIdx{t});
    end
    occurSameTimeList{ii} = lst;
    nOccurSameTime(ii) = numel(lst);    
end

% output ----
res = [];
res.nOccurSameLoc = nOccurSameLoc;
res.nOccurSameTime = nOccurSameTime;
res.occurSameLocList = occurSameLocList;
res.occurSameTimeList = occurSameTimeList;
end


















