function stepOne(~,~,f,adjust)
    
    fh = guidata(f);
    n = round(fh.sldMov.Value);
    btSt = getappdata(f,'btSt');
    if isfield(btSt,'isRunning') && btSt.isRunning
        pause(0.1);
        btSt.isRunning = false;
        setappdata(f,'btSt',btSt);
        return;
    end
    
    btSt.isRunning = true;
    setappdata(f,'btSt',btSt);
%     try
    if exist('adjust','var')
        if exist('adjust','var')
            n = max(1,min(n + adjust,fh.sldMov.Limits(2)));
        end
        fh.sldMov.Value = n;
    end
%     end
    ui.movStep(f,n);
    if(isfield(fh,'showcurves') && ~isempty(fh.showcurves))
        evtIdx = fh.showcurves(:,1);
        if ~isempty(evtIdx)
            channels = fh.showcurves(:,2);
            evtIdx1 = evtIdx(channels==1);
            evtIdx2 = evtIdx(channels==2);
            ui.evt.curveRefresh([],[],f,evtIdx1,evtIdx2);
        end
    end
    btSt.isRunning = false;
    setappdata(f,'btSt',btSt);
end