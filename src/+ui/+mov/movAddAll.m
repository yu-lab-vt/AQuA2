function movAddAll(~,~,f)
% Add All filtered events to favorite table

ov = getappdata(f,'ov');
%% Channel 1
ov0 = ov('Events_Red');
btSt = getappdata(f,'btSt');

xSel = ones(numel(ov0.sel),1);
if ~isempty(btSt.filterMsk1)
    xSel = xSel.*btSt.filterMsk1;
end

% add all filtered to favortie
evtIdx = find(xSel>0);
lst1 = btSt.evtMngrMsk1;
lst1 = union(lst1,evtIdx);
btSt.evtMngrMsk1 = lst1;

%% Channel 2
ov0 = ov('Events_Green');
xSel = ones(numel(ov0.sel),1);
if ~isempty(btSt.filterMsk2)
    xSel = xSel.*btSt.filterMsk2;
end

% add all filtered to favortie
evtIdx = find(xSel>0);
lst2 = btSt.evtMngrMsk2;
lst2 = union(lst2,evtIdx);
btSt.evtMngrMsk2 = lst2;
setappdata(f,'btSt',btSt);

% refresh event manager
ui.evt.evtMngrRefresh([],[],f);                       

% refresh movie
ui.movStep(f,[],[],1);

end


