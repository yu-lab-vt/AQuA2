function ftsLst = updtFeatureRegionLandmarkNetworkShow(f,datR,evtLst,ftsLst,gg,nCh)

btSt = getappdata(f,'btSt');
bd = getappdata(f,'bd');
opts = getappdata(f,'opts');
if(nCh==1)
    fm = btSt.filterMsk1;
else
    fm = btSt.filterMsk2;
end

if numel(fm)~=numel(evtLst)
    fm = [];
end
sz = size(datR);

% secondPerFrame = opts.frameRate;
muPerPix = opts.spatialRes;

% polygons
if bd.isKey('cell')
    bd0 = bd('cell');
    if sz(3)==1
        evtSpatialMask = false(sz(1:3));
        regLst = cell(numel(bd0),1);
        for ii=1:numel(bd0)
            pix00 = bd0{ii}{2};
            regLst{ii} = pix00;
            evtSpatialMask(pix00) = true;
        end
    else
        evtSpatialMask = bd0;
        regLst = bwconncomp(bd0).PixelIdxList;
    end
else
    regLst = [];
    evtSpatialMask = true(sz(1:3));
end

if bd.isKey('landmk')
    bd1 = bd('landmk');
    if sz(3)==1
        lmkLst = cell(numel(bd1),1);
        for ii=1:numel(bd1)
            lmkLst{ii} = bd1{ii}{2};
        end
    else
        lmkLst = bwconncomp(bd1).PixelIdxList;
    end
else
    lmkLst = [];
end

% use filtered events only
waitbar(0.6,gg);
evtx = evtLst;
if ~isempty(fm)
    for ii=1:numel(evtx)
        if fm(ii)==0
            evtx{ii} = [];
        end
    end
end

% landmark features
waitbar(0.7,gg);
ftsLst.region = [];
try
    if ~isempty(regLst) || ~isempty(lmkLst)
        fprintf('Updating region and landmark features ...\n')
        ftsLst.region = fea.getDistRegionBorderMIMO(evtx,datR,regLst,lmkLst,muPerPix,opts.minShow1);
        if bd.isKey('cell') && ~isempty(regLst)
            bd0 = bd('cell');
            cname = cell(numel(regLst),1);
            for i = 1:numel(regLst)
                if sz(3)==1
                    cname{i} = bd0{i}{4};
                    if(strcmp(cname{i},'None'))
                        cname{i} = num2str(i);
                    end
                else
                    cname{i} = num2str(i);
                end
            end
            ftsLst.region.cell.name = cname;
        end
        if bd.isKey('landmk') && ~isempty(lmkLst)
            bd0 = bd('landmk');
            lname = cell(numel(lmkLst),1);
            for i = 1:numel(lmkLst)
                if sz(3)==1
                    lname{i} = bd0{i}{4};
                    if(strcmp(lname{i},'None'))
                        lname{i} = num2str(i);
                    end
                else
                    lname{i} = num2str(i);
                end
            end
            ftsLst.region.landMark.name = lname;
        end
    end
catch
end

% update events to show
waitbar(1,gg);
try
    if ~isempty(regLst)
        regMask = sum(ftsLst.region.cell.memberIdx>0,2);
    end
    if(nCh == 1)
        btSt.regMask1 = regMask;
    else
        btSt.regMask2 = regMask;
    end
    setappdata(f,'btSt',btSt);
end


% update network features
evtx1 = evtx;
ftsLst.networkAll = [];
ftsLst.network = [];
try
    % remove the event outside the regions?
    if ~isempty(regLst)
        for ii=1:numel(evtx)
            loc00 = ftsLst.loc.xSpa{ii};
            if sum(evtSpatialMask(loc00))==0
                evtx1{ii} = [];
            end
        end
    end
    ftsLst.networkAll = fea.getEvtNetworkFeatures(evtx,sz);  % all filtered events
    ftsLst.network = fea.getEvtNetworkFeatures(evtx1,sz);  % events inside cells only
catch
end

end


