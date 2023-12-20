function addOne(~,~,f)
    % add one or multiple events to favorite list
    
    fh = guidata(f);
    btSt = getappdata(f,'btSt');
    
    try
        % evtNow = str2double(fh.toolsAddEvt.Value);        
        evtNow = eval(fh.toolsAddEvt2.Value);        
        lst = union(evtNow,btSt.evtMngrMsk2);        
        btSt.evtMngrMsk2 = lst;
        setappdata(f,'btSt',btSt);
        ui.evt.evtMngrRefresh([],[],f);
        fts = getappdata(f,'fts2');
        
        n0 = fts.curve.tBegin(evtNow(1));
        n1 = fts.curve.tEnd(evtNow(1));
        n = round((n0+n1)/2);        
        ui.movStep(f,n,[],1);
    catch
        msgbox('Invalid event ID')
    end
    
end
