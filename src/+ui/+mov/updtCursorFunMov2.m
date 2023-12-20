function updtCursorFunMov2(~,~,f,op)
    lbl = 'maskLst';
    btSt = getappdata(f,'btSt');
    % btSt.rmLbl = lbl;
    % setappdata(f,'btSt');
    
    fh = guidata(f);
    col = getappdata(f,'col');
    fh.AddBuilder.BackgroundColor = col;
    fh.RemoveBuilder.BackgroundColor = col;

    fh.imsMsk.ButtonDownFcn = [];
    
    if strcmp([op,lbl],btSt.clickSt)==1
        btSt.clickSt = [];
        setappdata(f,'btSt',btSt);
        return
    end
    
    if strcmp(op,'add')
        fh.AddBuilder.BackgroundColor = [.8,.8,.8];
        ui.mov.drawReg2([],[],f,op,lbl);
        fh.AddBuilder.BackgroundColor = col;
        fh.RemoveBuilder.BackgroundColor = col;
        btSt.clickSt = [];
    elseif strcmp(op,'rm')
        fh.RemoveBuilder.BackgroundColor = [.8,.8,.8];
        fh.imsMsk.ButtonDownFcn = {@ui.mov.movClick2,f,op,lbl};
        guidata(f,fh);
        btSt.clickSt = [op,lbl];
    else
        ui.mov.clearBuilderMask([],[],f,op,lbl);
    end
        
    setappdata(f,'btSt',btSt);    
end

