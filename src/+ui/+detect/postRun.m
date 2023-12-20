function postRun(~,~,f,evtLst1,evtLst2,datR1,datR2,ovName)
    
    opts = getappdata(f,'opts');
    
    % overlays object
    ov = getappdata(f,'ov');
    ov1 = ui.over.getOv(f,evtLst1,opts.sz,datR1,1);
    ov1.name = ovName;
    ov1.colorCodeType = {'Random'};
    ov([ovName,'_Red']) = ov1;
    ov2 = ui.over.getOv(f,evtLst2,opts.sz,datR2,2);
    ov2.name = ovName;
    ov2.colorCodeType = {'Random'};
    ov([ovName,'_Green']) = ov2;
    setappdata(f,'ov',ov);
    
    % update UI
    btSt = getappdata(f,'btSt');
    btSt.overlayDatSel = ovName;
    btSt.overlayColorSel = 'Random';
    setappdata(f,'btSt',btSt);
    ui.over.updateOvFtMenu([],[],f);
    
    % show movie with overlay
    ui.movStep(f);
    
end