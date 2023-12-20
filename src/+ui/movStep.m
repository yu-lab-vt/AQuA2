function [datxCol,overLayData,overLayColor] = movStep(f,n,ovOnly,updtAll)
% ----------- Modified by Xuelong Mi, 11/09/2022 -----------    
    % use btSt.sbs, btSt.leftView and btSt.rightView to determine what to show
    opts = getappdata(f,'opts');
    fh = guidata(f);
    scl = getappdata(f,'scl');
    btSt = getappdata(f,'btSt');
    L = opts.sz(3);
    
    if ~exist('ovOnly','var') || isempty(ovOnly)
        ovOnly = 0;
    end

    if ~exist('updtAll','var') || isempty(updtAll)
        updtAll = 0;
    end
        
    if ~exist('n','var') || isempty(n)
        n = round(fh.sldMov.Value);
    end
    
    %% channel 1
    dat1 = getappdata(f,'datOrg1');
    dat1 = dat1(:,:,:,n);
    if isfield(btSt,'GaussFilter') && btSt.GaussFilter==1
        dat1 = imgaussfilt(dat1,opts.smoXY);
    end
%     dat1 = se.myResize(dat1,1);
    dat1 = min(max(0,(dat1-scl.min)/max(scl.max-scl.min,0.01)),1);
    dat2 = [];
    %% channel 2
    if(~opts.singleChannel)
        dat2 = getappdata(f,'datOrg2');
        dat2 = dat2(:,:,:,n);
        if isfield(btSt,'GaussFilter') && btSt.GaussFilter==1
            dat2 = imgaussfilt(dat2,opts.smoXY);
        end
        dat2 = min(max(0,(dat2-scl.min)/max(scl.max-scl.min,0.01)),1);
    end
    
    overCol1 = [];
    overCol2 = [];
    overLayData = [];
    overLayColor = [];
    
    if L==1
        [overCol1,overCol2] = ui.over.getOvCurFrame(f,dat1,n);
    else
        dsSclXY = fh.sldDsXY.Value;
        dat1 = se.myResize(dat1,1/dsSclXY);
        if ~opts.singleChannel
            dat2 = se.myResize(dat2,1/dsSclXY);
        end
        [overLayData,overLayColor,overLayAlpha] = ui.over.getOvCurFrame3D(f,dat1,n,dsSclXY);
    end
    dat = cell(2,1); dat{1} = dat1; dat{2} = dat2;

    if ovOnly>0
        if L==1
            datxCol = cell(2,1);
            datxCol{1} = cat(3,dat1,dat1,dat1) + overCol1;
            datxCol{2} = cat(3,dat2,dat2,dat2) + overCol2;
            return;
        else
            datxCol = dat;
            return;
        end
    end
    
    %% overlay
    if ~fh.sbs.Value
        if L == 1
            fh.ims.im1.CData = flipud(cat(3,dat1,dat1,dat1)*scl.bri1 + overCol1);
            ui.mov.addPatchLineText(f,fh.mov,n,updtAll);
            fh.mov.XLim = scl.wrg;
            fh.mov.YLim = scl.hrg;
        else
            fh.ims.im1.Data = dat1;
            fh.ims.im1.OverlayData = overLayData{1};
            fh.ims.im1.OverlayColormap = overLayColor{1};
            fh.ims.im1.OverlayAlphamap = overLayAlpha{1};
        end
    else 
        viewName = {'leftView','rightView'};
        imName = {'im2a','im2b'};
        ims = {fh.ims.im2a,fh.ims.im2b};
        axLst = {fh.movL,fh.movR};
        thrAct = fh.sldActThr.Value;
        briScl = [fh.sldBriL.Value,fh.sldBriR.Value];
        channelSelect = [btSt.ChannelL,btSt.ChannelR];
        overCol = cell(1,2); overCol{1} = overCol1; overCol{2} = overCol2;
        for ii= 1:2
            curType = btSt.(viewName{ii});
            axNow = axLst{ii};
            curDat = dat{channelSelect(ii)};
            curOverCol = overCol{channelSelect(ii)};
            % clean all patches
            if updtAll>0
                types = {'quiver','line','patch','text'};
                for jj=1:numel(types)
                    h00 = findobj(axNow,'Type',types{jj});
                    if ~isempty(h00)
                        delete(h00);
                    end
                end
            end
            switch curType
                case 'Raw'
                    if L==1
                        ims{ii}.CData = flipud(cat(3,curDat,curDat,curDat)*briScl(ii));
                    else
                        ims{ii}.Data = curDat;
                        ims{ii}.OverlayData = [];
                    end
                case 'dF / sigma'
                        if channelSelect(ii)==1
                            dF = getappdata(f,'dF1');
                        else
                            dF = getappdata(f,'dF2');
                        end
                        nodF= false;
                        if (~isempty(dF)) 
                            dF = dF(:,:,:,n);  
                        else 
                            dF = curDat; 
                            nodF = true;
                        end
                        if channelSelect(ii)==1
                            dF = dF/opts.maxdF1;  % re-scale
                        else
                            dF = dF/opts.maxdF2;  % re-scale
                        end
                        

                        if L==1
                            ims{ii}.CData = flipud(cat(3,dF,dF,dF)*briScl(ii));
                        else
                            if ~nodF
                                ims{ii}.Data = se.myResize(dF,1/dsSclXY);
                            else
                                ims{ii}.Data = curDat;
                            end
                            ims{ii}.OverlayData = [];
                        end
                case 'Threshold preview'
                    if channelSelect(ii)==1
                        dF = getappdata(f,'dF1');
                    else
                        dF = getappdata(f,'dF2');
                    end
                    dF = dF(:,:,:,n);
                    if L==1
                        col = [0.64,0.48,0.16]; 
                        thrData = zeros(opts.sz(1),opts.sz(2),3);
                        bd = getappdata(f,'bd');
                        evtSpatialMask = true(opts.sz(1:3));
                        if bd.isKey('cell')
                            bd0 = bd('cell');
                            if numel(bd0) > 0
                                evtSpatialMask = false(opts.sz(1:3));
                                for iiii=1:numel(bd0)
                                    p0 = bd0{iiii}{2};
                                    evtSpatialMask(p0) = true;
                                end
                            end
                        end
                        mask000 = single(evtSpatialMask & dF>thrAct);
                        for c = 1:3
                            thrData(:,:,c) = col(c)*mask000;
                        end
                        thrData = thrData + cat(3,curDat,curDat,curDat);
                        ims{ii}.CData = flipud(thrData*briScl(ii));
                    else
                        col = [0,0,0;0.64,0.48,0.16]; 
                        ims{ii}.Data = curDat;
                        thrData = zeros(opts.sz(1:3),'uint8');
                        thrData(dF>thrAct) = 1;
                        ims{ii}.OverlayData = round(se.myResize(thrData,1/dsSclXY));
                        ims{ii}.OverlayColormap = col;
                    end

                case 'Raw + overlay'
                    if L==1
                        ims{ii}.CData = flipud(cat(3,curDat,curDat,curDat)*briScl(ii) + curOverCol);
                        ui.mov.addPatchLineText(f,axNow,n,updtAll);
                    else
                        ims{ii}.Data = curDat;
                        ims{ii}.OverlayData = overLayData{channelSelect(ii)};
                        ims{ii}.OverlayColormap = overLayColor{channelSelect(ii)};
                        ims{ii}.OverlayAlphamap = overLayAlpha{channelSelect(ii)};
                    end
                case 'Rising map (20%)'
                    ui.mov.showRisingMap(f,imName{ii},n,curType,channelSelect(ii));
                case 'Rising map (50%)'
                    ui.mov.showRisingMap(f,imName{ii},n,curType,channelSelect(ii));
                case 'Rising map (80%)'
                    ui.mov.showRisingMap(f,imName{ii},n,curType,channelSelect(ii));
                case 'Maximum Projection'
                    if channelSelect(ii)==1
                        datM = fh.maxPro1;
                    else
                        datM = fh.maxPro2;
                    end
                    datM = (datM-scl.min)/max(scl.max-scl.min,0.01);
                    if L==1
                        datM = cat(3,datM,datM,datM)*briScl(ii);
                        ims{ii}.CData = flipud(datM);
                        ui.mov.addPatchLineText(f,axNow,n,updtAll);
                    else
                        ims{ii}.Data = se.myResize(datM,1/dsSclXY);
                        ims{ii}.OverlayData = [];
                        ims{ii}.OverlayAlphamap = overLayAlpha;
                    end
                    
                case 'Average Projection'
                    if channelSelect(ii)==1
                        datM = fh.averPro1;
                    else
                        datM = fh.averPro2;
                    end
                    datM = (datM-scl.min)/max(scl.max-scl.min,0.01);
                    if L==1
                        datM = cat(3,datM,datM,datM)*briScl(ii);
                        ims{ii}.CData = flipud(datM);
                        ui.mov.addPatchLineText(f,axNow,n,updtAll);    
                    else
                        ims{ii}.Data = se.myResize(datM,1/dsSclXY);
                        ims{ii}.OverlayData = [];
                        ims{ii}.OverlayAlphamap = overLayAlpha;
                    end 
            end
        end
    end

    if L==1
        fh.movL.XLim = scl.wrg;
        fh.movL.YLim = scl.hrg;
        fh.movR.XLim = scl.wrg;
        fh.movR.YLim = scl.hrg;
    end
    % frame number
    ui.mov.updtMovInfo(f,n,opts.sz(4));
end



