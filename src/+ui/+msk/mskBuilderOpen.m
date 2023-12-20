function mskBuilderOpen(~,~,f)
    fh = guidata(f);
    
    fgOK = 0;
    bgOK = 0;
    opts = getappdata(f,'opts');
    bd = getappdata(f,'bd');
    btSt = getappdata(f,'btSt');
    if bd.isKey('maskLst')
        bdMsk = bd('maskLst');
        for ii=1:numel(bdMsk)
            rr = bdMsk{ii};
            if strcmp(rr.type,'Default CH1 (operation not applicable)')
                fgOK = 1;
            end
            if strcmp(rr.type,'Default CH2 (operation not applicable)')
                bgOK = 1;
            end
        end
    end
    
    if opts.sz(3)>1
        bkColors = [0,0,0;
            0,0,0;
            0 0.3290 0.5290;
            .5,.5,.5;
            1,1,1];
        gdColors = [0,0,0;
            .3,.3,.3;
            0 0.5610 1;
            .8,.8,.8;
            1,1,1];
        fh.imgMsk.BackgroundColor = bkColors(btSt.bkCol,:);
        fh.imgMsk.GradientColor = gdColors(btSt.bkCol,:);
        fh.bkColMsk = btSt.bkCol;
        guidata(f,fh);
    end

    if fgOK==0
        ui.msk.readMsk([],[],f,'self_CH1','Default CH1 (operation not applicable)',0);
    end
    if (bgOK==0 & ~opts.singleChannel)
        ui.msk.readMsk([],[],f,'self_CH2','Default CH2 (operation not applicable)',0);
    end
    
    ui.msk.mskLstViewer([],[],f,'refresh');
    
    fh.Card1.Visible = 'off';
    fh.Card2.Visible = 'off';
    fh.Card3.Visible = 'off';
    fh.Card4.Visible = 'on';
    f.KeyReleaseFcn = [];