function mskBuilderOpen(~,~,f)
    fh = guidata(f);
    opts = getappdata(f,'opts');
    bd = getappdata(f,'bd');
    btSt = getappdata(f,'btSt');
    
    H = opts.sz(1); W = opts.sz(2); 
    if numel(opts.sz) >= 3
        L = opts.sz(3);
    else
        L = 1;
    end
    
    isMskEmpty = true;
    if bd.isKey('maskLst')
        bdMsk = bd('maskLst');
        if ~isempty(bdMsk)
            isMskEmpty = false;
        end
    else
        bdMsk = {};
    end
    
    % Update: initialize default layers only when needed.
    if isMskEmpty
        ui.msk.readMsk([],[],f,'self_CH1','region',[]); 
        if ~opts.singleChannel
            ui.msk.readMsk([],[],f,'self_CH2','region',[]);
        end
        bdMsk = bd('maskLst'); 
    end
    
    % Update: import manual objects once, then mark them as imported.
    if L == 1
        manualCellMsk = false(H,W);
        manualLmkMsk = false(H,W);
    else
        manualCellMsk = false(H,W,L);
        manualLmkMsk = false(H,W,L);
    end
    
    hasManualCell = false;
    if bd.isKey('cell')
        cells = bd('cell');
        for i = 1:numel(cells)
            if numel(cells{i})>=3 && strcmp(cells{i}{3}, 'manual')
                manualCellMsk(cells{i}{2}) = true;
                hasManualCell = true;
                cells{i}{3} = 'imported';
            end
        end
        bd('cell') = cells;
    end
    
    hasManualLmk = false;
    if bd.isKey('landmk')
        lmks = bd('landmk');
        for i = 1:numel(lmks)
            if numel(lmks{i})>=3 && strcmp(lmks{i}{3}, 'manual')
                manualLmkMsk(lmks{i}{2}) = true;
                hasManualLmk = true;
                lmks{i}{3} = 'imported';
            end
        end
        bd('landmk') = lmks;
    end
    
    datAvg = fh.averPro1;
    if max(datAvg(:)) > 0
        datAvg = datAvg / nanmax(datAvg(:));
    end
    
    timeStamp = datestr(now, 'HH:MM:SS');
    
    if hasManualCell
        rrC = [];
        rrC.name = ['Manual Regions (', timeStamp, ')'];
        rrC.datAvg = datAvg; 
        rrC.type = 'region';
        rrC.thr = 0.5;
        rrC.minSz = 1;
        rrC.maxSz = H*W*L;
        rrC.mask = manualCellMsk;
        rrC.morphoChange = 0;
        bdMsk{end+1} = rrC;
    end
    
    if hasManualLmk
        rrL = [];
        rrL.name = ['Manual Landmarks (', timeStamp, ')'];
        rrL.datAvg = datAvg; 
        rrL.type = 'landmark';
        rrL.thr = 0.5;
        rrL.minSz = 1;
        rrL.maxSz = H*W*L;
        rrL.mask = manualLmkMsk;
        rrL.morphoChange = 0;
        bdMsk{end+1} = rrL;
    end
    
    bd('maskLst') = bdMsk;
    setappdata(f,'bd',bd);
    
    if L > 1
        bkColors = [0,0,0; 0,0,0; 0 0.3290 0.5290; .5,.5,.5; 1,1,1];
        gdColors = [0,0,0; .3,.3,.3; 0 0.5610 1; .8,.8,.8; 1,1,1];
        fh.imgMsk.BackgroundColor = bkColors(btSt.bkCol,:);
        fh.imgMsk.GradientColor = gdColors(btSt.bkCol,:);
        fh.bkColMsk = btSt.bkCol;
        guidata(f,fh);
    end
    
    ui.msk.mskLstViewer([],[],f,'open');
    
    fh.Card1.Visible = 'off';
    fh.Card2.Visible = 'off';
    fh.Card3.Visible = 'off';
    fh.Card4.Visible = 'on';
    f.KeyReleaseFcn = [];
end
