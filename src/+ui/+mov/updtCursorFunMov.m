function updtCursorFunMov(~,~,f,op,lbl)
    btSt = getappdata(f,'btSt');
    opts = getappdata(f,'opts');
    % btSt.rmLbl = lbl;
    % setappdata(f,'btSt');
    
    fh = guidata(f);
    col = [.96,.96,.96];
    fh.AddLm.BackgroundColor = col;
    fh.AddCell.BackgroundColor = col;
    fh.RmLm.BackgroundColor = col;
    fh.RmCell.BackgroundColor = col;
    fh.DragLm.BackgroundColor = col;
    fh.DragCell.BackgroundColor = col;
    fh.NameCell.BackgroundColor = col;
    fh.NameLm.BackgroundColor = col;
    fh.viewFavClick.BackgroundColor = col;
    fh.delResClick.BackgroundColor = col;
    fh.extract.BackgroundColor = col;
    fh.checkROI.BackgroundColor = col;
    fh.checkROI.BackgroundColor = col;
    
    if opts.sz(3)==1
        fh.ims.im1.ButtonDownFcn = [];
        fh.ims.im2a.ButtonDownFcn = [];
        fh.ims.im2b.ButtonDownFcn = [];
    end
    
    if strcmp([op,lbl],btSt.clickSt)==1
        btSt.clickSt = [];
        setappdata(f,'btSt',btSt);
        return
    end
    
    switch lbl
        case 'cell'
            if strcmp(op,'add')
                fh.AddCell.BackgroundColor = [.8,.8,.8];
            elseif strcmp(op,'rm')
                fh.RmCell.BackgroundColor = [.8,.8,.8];
            elseif strcmp(op,'name')
                fh.NameCell.BackgroundColor = [.8,.8,.8];
            elseif strcmp(op,'drag')
                fh.DragCell.BackgroundColor = [.8,.8,.8];
            end
        case 'landmk'
            if strcmp(op,'add')
                fh.AddLm.BackgroundColor = [.8,.8,.8];
            elseif strcmp(op,'rm')
                fh.RmLm.BackgroundColor = [.8,.8,.8];
            elseif strcmp(op,'name')
                fh.NameLm.BackgroundColor = [.8,.8,.8];
            elseif strcmp(op,'drag')
                fh.DragLm.BackgroundColor = [.8,.8,.8];
            end
        case 'viewFav'
            if fh.viewFavClick.Value==1
                fh.viewFavClick.BackgroundColor = [.8,.8,.8];
            end
        case 'delRes'
            if fh.delResClick.Value==1
                fh.delResClick.BackgroundColor = [.8,.8,.8];
            end
        case 'roi'
            if fh.checkROI.Value==1
                fh.checkROI.BackgroundColor = [.8,.8,.8];
            end
    end
    
    if strcmp(op,'add')
        ui.mov.drawReg([],[],f,op,lbl);
        fh.AddLm.BackgroundColor = col;
        fh.AddCell.BackgroundColor = col;
        btSt.clickSt = [];
    elseif strcmp(op,'check')
        fh.viewFavClick.Value = 0;
        fh.delResClick.Value = 0;
        ui.mov.drawReg([],[],f,op,lbl);
        fh.checkROI.BackgroundColor = col;
        fh.checkROI.BackgroundColor = col;
        btSt.clickSt = [];
        fh.checkROI.Value = 0;
    elseif strcmp(op,'addrm')&&strcmp(lbl,'addAll')
        ui.mov.movAddAll([],[],f);
        btSt = getappdata(f,'btSt');
    elseif strcmp(op,'drag')
        ui.mov.dragReg([],[],f,op,lbl);
        btSt.clickSt = [];
    else
        if strcmp(lbl,'viewFav') || strcmp(lbl,'delRes')
            if strcmp(lbl,'viewFav')
                fh.delResClick.Value = 0;
            else
                fh.viewFavClick.Value = 0;
            end
        end
        if opts.sz(3)==1
            % 2D
            fh.ims.im1.ButtonDownFcn = {@ui.mov.movClick,f,op,lbl};
            fh.ims.im2a.ButtonDownFcn = {@ui.mov.movClick,f,op,lbl};
            fh.ims.im2b.ButtonDownFcn = {@ui.mov.movClick,f,op,lbl};
            guidata(f,fh);
            btSt.clickSt = [op,lbl];
        else
            if strcmp(lbl,'viewFav') || strcmp(lbl,'delRes')
                % 3D view / remove
                if fh.viewFavClick.Value==1 || fh.delResClick.Value==1
                    fh.filterTable.Visible = 'off';
                    fh.sliceSelect.Visible = 'on';
                    if fh.Pan.Value == 0
                        fh.Pan.Value = 1;
                        ui.mov.sliceView(fh.Pan,[],f);
                    end
                else
                    fh.filterTable.Visible = 'on';
                    fh.sliceSelect.Visible = 'off';
                end
            end
        end
    end
        
    setappdata(f,'btSt',btSt);    
end

