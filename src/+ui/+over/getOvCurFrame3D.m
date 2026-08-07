function [labelMaps,colMaps,alphaMaps] = getOvCurFrame3D(f,datx,n,dsSclXY)

[H0,W0,L0] = size(datx);

fh = guidata(f);
scl = getappdata(f,'scl');
btSt = getappdata(f,'btSt');
opts = getappdata(f,'opts');
sclOv = scl.briOv;

% Update 2026-08-07: use a fixed 8-bit map for R2023a+ label overlays.
v_str = version('-release');
useFixedLabelMap = str2double(v_str(1:4)) >= 2023;
labelMap = [];
colMap = [0,0,0];
alphaMap = 0;
labelMap2 = [];
colMap2 = [0,0,0];
alphaMap2 = 0;

labelMaps = cell(2,1); alphaMaps = cell(2,1); colMaps = cell(2,1);
labelMaps{1} = labelMap;
alphaMaps{1} = alphaMap;
colMaps{1} = colMap;

labelMaps{2} = labelMap2;
alphaMaps{2} = alphaMap2;
colMaps{2} = colMap2;

if ~strcmp(btSt.overlayDatSel,'None')
    % show movie with overlay
    if useFixedLabelMap
        labelMap = zeros(H0,W0,L0,'uint8');
    else
        labelMap = zeros(H0,W0,L0);
    end
    ov = getappdata(f,'ov');
    ov1 = ov([btSt.overlayDatSel,'_Red']);
    x1 = ov1.frame{n};
    c1 = ov1.col;
    if isfield(ov1,'colVal') && strcmp(btSt.overlayColorSel,'Random')==0
        v1 = ov1.colVal;
        c1 = ui.over.reMapCol(btSt.mapNow,v1,scl);
    end
    if ~isempty(x1)
        if useFixedLabelMap
            colMap = zeros(256,3);
            alphaMap = zeros(256,1);
        else
            colMap = zeros(numel(x1.idx)+1,3);
            alphaMap = ones(numel(x1.idx)+1,1) * (1-fh.sldOverlayTrans.Value);
        end
        for ii=1:numel(x1.idx)
            idx1 = x1.idx(ii);
            pix0 = x1.pix{ii};
            [ih,iw,il] = ind2sub([opts.sz(1:3)],pix0);
            pix0 = unique(sub2ind([H0,W0,L0],ceil(ih/dsSclXY),ceil(iw/dsSclXY),il));
            lbl = ii;
            if useFixedLabelMap
                lbl = mod(ii-1,255)+1;
            end
            col0 = c1(idx1,:);
            labelMap(pix0) = lbl;
            hsvColor = rgb2hsv(col0);
            hsvColor(3) = min(1,hsvColor(3)*sclOv);
            if sum(ismember(idx1,btSt.evtMngrMsk1))>0
                hsvColor(3) = 1;
                alphaMap(lbl+1) = min(1,1-fh.sldOverlayTrans.Value+0.2);
            elseif useFixedLabelMap
                alphaMap(lbl+1) = 1-fh.sldOverlayTrans.Value;
            end
            if ov1.sel(idx1)==0 || sum(ismember(idx1,btSt.rmLst1))>0
                alphaMap(lbl+1) = 0;
            end

            colMap(lbl+1,:) = hsv2rgb(hsvColor);

        end
        alphaMap(1) = 0;

        if fh.Pan.Value == 1
            selectedLabel = double(labelMap(round(fh.yPos.Value),round(fh.xPos.Value),round(fh.zPos.Value)));
            col = colMap(selectedLabel+1,:);
            hsvColor = rgb2hsv(col);
            hsvColor(3) = 1;
            colMap(selectedLabel+1,:) = hsv2rgb(hsvColor);
        end
    end

    labelMaps{1} = labelMap;
    alphaMaps{1} = alphaMap;
    colMaps{1} = colMap;
    if opts.singleChannel
        return;
    end

    if useFixedLabelMap
        labelMap2 = zeros(H0,W0,L0,'uint8');
    else
        labelMap2 = zeros(H0,W0,L0);
    end
    colMap2 = [0,0,0];
    alphaMap2 = 0;

    % show movie with overlay
    ov = getappdata(f,'ov');
    ov1 = ov([btSt.overlayDatSel,'_Green']);
    x1 = ov1.frame{n};
    c1 = ov1.col;
    if isfield(ov1,'colVal') && strcmp(btSt.overlayColorSel,'Random')==0
        v1 = ov1.colVal;
        c1 = ui.over.reMapCol(btSt.mapNow,v1,scl);
    end
    if ~isempty(x1)
        if useFixedLabelMap
            colMap2 = zeros(256,3);
            alphaMap2 = zeros(256,1);
        else
            colMap2 = zeros(numel(x1.idx)+1,3);
            alphaMap2 = ones(numel(x1.idx)+1,1) * (1-fh.sldOverlayTrans.Value);
        end
        for ii=1:numel(x1.idx)
            idx1 = x1.idx(ii);
            pix0 = x1.pix{ii};
            [ih,iw,il] = ind2sub([opts.sz(1:3)],pix0);
            pix0 = unique(sub2ind([H0,W0,L0],ceil(ih/dsSclXY),ceil(iw/dsSclXY),il));
            lbl = ii;
            if useFixedLabelMap
                lbl = mod(ii-1,255)+1;
            end
            col0 = c1(idx1,:);
            labelMap2(pix0) = lbl;
            hsvColor = rgb2hsv(col0);
            hsvColor(3) = min(1,hsvColor(3)*sclOv);
            if sum(ismember(idx1,btSt.evtMngrMsk2))>0
                hsvColor(3) = 1;
                alphaMap2(lbl+1) = min(1,1-fh.sldOverlayTrans.Value+0.2);
            elseif useFixedLabelMap
                alphaMap2(lbl+1) = 1-fh.sldOverlayTrans.Value;
            end
            if ov1.sel(idx1)==0 || sum(ismember(idx1,btSt.rmLst2))>0
                alphaMap2(lbl+1) = 0;
            end
            
            colMap2(lbl+1,:) = hsv2rgb(hsvColor);
            
        end
        alphaMap2(1) = 0;

        if fh.Pan.Value == 1
            selectedLabel = double(labelMap2(round(fh.yPos.Value),round(fh.xPos.Value),round(fh.zPos.Value)));
            col = colMap2(selectedLabel+1,:);
            hsvColor = rgb2hsv(col);
            hsvColor(3) = 1;
            colMap2(selectedLabel+1,:) = hsv2rgb(hsvColor);
        end
    end
end
labelMaps{2} = labelMap2;
alphaMaps{2} = alphaMap2;
colMaps{2} = colMap2;
end
