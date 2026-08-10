function regionSL(~,~,f,op,lbl)
    bd = getappdata(f,'bd');
    opts = getappdata(f,'opts');
    
    if strcmp(op,'save')
        if strcmp(lbl,'cell')
            definput = {'_Cell.mat'};
            selname = inputdlg('Type desired suffix for Region file:',...
                'Region file',[1 75],definput);

            selname = char(selname);
            if isempty(selname)
                return;
            end
        else
            definput = {'_LandMark.mat'};
            selname = inputdlg('Type desired suffix for Region file:',...
                'Region file',[1 75],definput);

            selname = char(selname);
            if isempty(selname)
                return;
            end
        end
        file0 = [opts.fileName1,selname];
        clear definput selname

        %file0 = [opts.fileName,'_AQuA']; SP, 18.07.16
        selpath = uigetdir(opts.filePath1,'Choose output folder');
        path0 = [selpath,filesep,file0];
        if ~isnumeric(selpath)
            if bd.isKey(lbl)
                bd0 = bd(lbl);
            else
                bd0 = [];
            end
            save(path0,'bd0');
        end
    else
       [file,path] = uigetfile( ...
           {'*.mat;*.zip;*.tif;*.tiff','Region files (*.mat, *.zip, *.tif, *.tiff)'; ...
            '*.mat','AQuA2 region files (*.mat)'; ...
            '*.zip','ImageJ ROI archives (*.zip)'; ...
            '*.tif;*.tiff','Binary mask images (*.tif, *.tiff)'}, ...
           'Choose Region file',opts.filePath1);
       if ~isnumeric([path,file])
           [~,~,ext] = fileparts(file);
           if strcmpi(ext,'.mat')
               loadContent = load([path,file],'bd0');
               bd(lbl) = loadContent.bd0;
               setappdata(f,'bd',bd);
               ui.movStep(f,[],[],1);
           elseif any(strcmpi(ext,{'.tif','.tiff'}))
               [bd,nAdded] = importTiffMask(path,file,bd,opts,lbl);
               if nAdded > 0
                   setappdata(f,'bd',bd);
                   ui.movStep(f,[],[],1);
               end
           else
               prompt = {'Pixel number of growing ROIs (0: no grow):'};
               dlgtitle = 'Input';
               dims = [1 60];
               definput = {'0'};
               answer = inputdlg(prompt,dlgtitle,dims,definput);
               if(isempty(answer)) return; end
               nGrow = round(str2double(answer{1}));
       
               [cvsROI] = ReadImageJROI([path,file]);
               H = opts.sz(1)+2*opts.regMaskGap;
               W = opts.sz(2)+2*opts.regMaskGap;
               [sRegions] = ROIs2Regions(cvsROI, [W,H]);
               ROIinfo0 = cell(numel(sRegions.PixelIdxList),1);
               if bd.isKey(lbl)
                    bd0 = bd(lbl);
               else
                    bd0 = [];
               end
               if bd.isKey('roi')
                    ROIinfo = bd('roi');
               else
                    ROIinfo = cell(0,1);
               end
               bd00 = cell(numel(sRegions.PixelIdxList),1);
               nBd = numel(bd0);
               if(nBd==0) bd0 = cell(0,1); end;
               for i = 1:numel(sRegions.PixelIdxList)
                   pix = sRegions.PixelIdxList{i};
                   [iw,ih] = ind2sub([W,H],pix);
                   ih = ih - opts.regMaskGap;
                   iw = iw - opts.regMaskGap;
                   select = ih>0 & iw>0 & ih<=opts.sz(1) & iw<=opts.sz(2);
                   pix = sub2ind(opts.sz(1:2),ih(select),iw(select));
                   
                   pix = growRegion(pix,opts.sz(1:2),nGrow);
                   msk = false(opts.sz(1:2));
                   msk(pix) = true;
                   tmp{1} = bwboundaries(msk);
                   tmp{2} = pix;
                   tmp{3} = 'manual';
                   tmp{4} = 'None';
                   bd00{i} = tmp;
                   ROIinfo0{i}.pix = pix;
                   ROIinfo0{i}.name = num2str(nBd+i);
               end
               
               bd0(nBd + 1:nBd + numel(bd00)) = bd00;
               bd(lbl) = bd0;
               nRoi = numel(ROIinfo);
               ROIinfo(nRoi + 1:nRoi + numel(ROIinfo0)) = ROIinfo0;
               bd('roi') = ROIinfo;
               setappdata(f,'bd',bd);
               ui.movStep(f,[],[],1);
           end
       end
    end 
end

function [bd,nAdded] = importTiffMask(path,file,bd,opts,lbl)
% Import a white-on-black TIFF as one region per connected component.
% A full-size source image is cropped by regMaskGap when necessary.
rawMask = imread(fullfile(path,file));
if ndims(rawMask) == 3
    rawMask = max(rawMask,[],3);  % support RGB masks without changing white foreground
end
if ~ismatrix(rawMask)
    error('ui:mov:regionSL:InvalidTiffMask', ...
        'The TIFF mask must contain one two-dimensional image.');
end

mask = rawMask > min(rawMask(:));
targetSize = opts.sz(1:2);
gap = opts.regMaskGap;
fullSize = targetSize + 2*gap;
if isequal(size(mask), targetSize)
    % The TIFF is already in the AQuA2 working coordinate system.
elseif isequal(size(mask), fullSize)
    mask = mask(gap+1:end-gap,gap+1:end-gap);
else
    error('ui:mov:regionSL:MaskSizeMismatch', ...
        ['TIFF mask size is [%d %d]; expected either the AQuA2 image size ' ...
        '[%d %d] or the uncropped size [%d %d].'], ...
        size(mask,1),size(mask,2),targetSize,fullSize);
end

components = bwconncomp(mask,8);
nAdded = components.NumObjects;
if nAdded == 0
    warning('ui:mov:regionSL:EmptyTiffMask', ...
        'The selected TIFF contains no non-background pixels.');
    return
end

if bd.isKey(lbl)
    bd0 = bd(lbl);
else
    bd0 = cell(0,1);
end
if bd.isKey('roi')
    ROIinfo = bd('roi');
else
    ROIinfo = cell(0,1);
end

nExisting = numel(bd0);
nExistingRoi = numel(ROIinfo);
for componentIndex = 1:nAdded
    pix = components.PixelIdxList{componentIndex};
    region = cell(1,4);
    % BWCONNCOMP indices are in the same 2-D coordinates as the movie.
    componentMask = false(targetSize);
    componentMask(pix) = true;
    region{1} = bwboundaries(componentMask);
    region{2} = pix;
    region{3} = 'imported';
    region{4} = 'None';
    bd0{nExisting + componentIndex} = region;

    ROIinfo{nExistingRoi + componentIndex}.pix = pix;
    ROIinfo{nExistingRoi + componentIndex}.name = num2str(nExisting + componentIndex);
end
bd(lbl) = bd0;
bd('roi') = ROIinfo;
end

function pixGrow = growRegion(pix,sz,nGrow)
    if(nGrow <= 0)
        pixGrow = pix;
        return;
    end
    H = sz(1);
    W = sz(2);
    dh = [-1,0,1,-1,1,-1,0,1];
    dw = [-1,-1,-1,0,0,1,1,1];
    
    newCandidate = pix;
    pixGrow = pix;
    for k = 1:nGrow
        [ih0,iw0] = ind2sub([H,W],newCandidate);
        newCandidate = [];
        for i = 1:numel(dw)
           ih = max(1,min(H,ih0+dh(i)));
           iw = max(1,min(W,iw0+dw(i)));
           newIhw = sub2ind([H,W],ih,iw);
           newCandidate = [newCandidate;newIhw];
        end
        newCandidate = setdiff(newCandidate,pixGrow);
        pixGrow = [pixGrow;newCandidate];
    end
    
end
