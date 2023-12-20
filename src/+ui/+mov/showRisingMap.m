function showRisingMap(f,imName,n,curType,ch)

btSt = getappdata(f,'btSt');
if ch == 1
    evtLst = btSt.evtMngrMsk1;
    fts = getappdata(f,'fts1');
else
    evtLst = btSt.evtMngrMsk2;
    fts = getappdata(f,'fts2');
end

opts = getappdata(f,'opts');
t0 = fts.loc.t0;
t1 = fts.loc.t1;
mskx = false(numel(t0),1);
mskx(evtLst) = true;
evtSel = find(mskx & t0(:)<=n & t1(:)>=n);
sz = opts.sz;
fh = guidata(f);
maxRs = 0;
minRs = inf;
if ch==1
    riseLst = getappdata(f,'riseLst1');
else
    riseLst = getappdata(f,'riseLst2');
end

if isempty(riseLst)
    return
end

riseMap = nan(sz(1),sz(2),sz(3));

for ii=1:numel(evtSel)
    rr = riseLst{evtSel(ii)};
    switch curType
        case 'Rising map (20%)'
            riseMap(rr.rgh,rr.rgw,rr.rgl) = nanmax(rr.dlyMap20,riseMap(rr.rgh,rr.rgw,rr.rgl));
        case 'Rising map (50%)'
            riseMap(rr.rgh,rr.rgw,rr.rgl) = nanmax(rr.dlyMap50,riseMap(rr.rgh,rr.rgw,rr.rgl));
        case 'Rising map (80%)'
            riseMap(rr.rgh,rr.rgw,rr.rgl) = nanmax(rr.dlyMap80,riseMap(rr.rgh,rr.rgw,rr.rgl));
    end
    maxDly = rr.maxDly;
    minDly = rr.minDly;

    maxRs = max(maxRs,maxDly);
    minRs = min(minRs,minDly);
end
 
jm = jet(1000);
if sz(3) == 1
    rs = riseMap(~isnan(riseMap(:)));
    if maxRs>minRs
        rs = round((rs-minRs)/(maxRs-minRs)*999+1);
    else
        rs = rs*0+500;
    end
    rId = max(min(rs,1000),1);
    rsCol = jm(rId,:);
    riseMapCol = ones(sz(1)*sz(2),3);
    riseMapCol(~isnan(riseMap(:)),:) = rsCol;
    riseMapCol = reshape(riseMapCol,sz(1),sz(2),3);
        
    % rising map
    fh.ims.(imName).CData = flipud(riseMapCol);
else
    dsSclXY = fh.sldDsXY.Value;
    fh.ims.(imName).Data = se.myResize(zeros(sz(1:3)),1/dsSclXY);
    riseMap = round(riseMap);
    riseMap(isnan(riseMap)) = 0;
    pixLst = label2idx(riseMap);
    szCluster = cellfun(@numel,pixLst);
    pixLst = pixLst(szCluster>0);
    overlayMap = zeros(size(fh.ims.(imName).Data));
    cols = zeros(numel(pixLst)+1,3);
    for i = 1:numel(pixLst)
        pix = pixLst{i};
        delay = riseMap(pix(1));
        [ih,iw,il] = ind2sub(sz(1:3),pix);
        if maxRs>minRs
            rId = round((delay-minRs)/(maxRs-minRs)*999+1);
        else
            rId = 500;
        end
        rId = max(min(rId,1000),1);
        pix = sub2ind([size(overlayMap)],ceil(ih/dsSclXY),ceil(iw/dsSclXY),il);
        overlayMap(pix) = i;
        cols(i+1,:) = jm(rId,:);
    end

    fh.ims.(imName).AlphaData = overlayMap>0;
    fh.ims.(imName).OverlayData = overlayMap;
    fh.ims.(imName).OverlayColormap = cols;
end

switch imName
    case 'im2a'
        axNow = fh.movLColMap;
    case 'im2b'
        axNow = fh.movRColMap;
end
    
% color map
gap0 = (maxRs-minRs)/98;
if gap0>0
    m0 = minRs:gap0:maxRs;
else
    m0 = zeros(1,99)+minRs;
end

cMap1 = jet(numel(m0));
ui.over.updtColMap(axNow,m0,cMap1,1);    

end



























