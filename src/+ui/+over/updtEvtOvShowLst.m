function updtEvtOvShowLst(~,~,f)
% updtEvtOvShowLst update the list of events whose overlay should be shown
% determined by filter and drawn regions

btSt = getappdata(f,'btSt');
ov = getappdata(f,'ov');

%% channel 1
name = 'Events_Red'; 
ov0 = ov(name);
xSel = true(numel(ov0.sel),1);
if ~isempty(btSt.filterMsk1)
    xSel = xSel.*btSt.filterMsk1;
end
if ~isempty(btSt.regMask1)
    xSel = xSel.*btSt.regMask1;
end
if ~isempty(btSt.rmLst1)
    msk00 = ones(numel(ov0.sel),1);
    msk00(btSt.rmLst1) = 0;
    xSel = xSel.*msk00;
end
ov0.sel = xSel>0;
ov(name) = ov0;
%% channel 2
name = 'Events_Green';
ov0 = ov(name);
xSel = true(numel(ov0.sel),1);
if ~isempty(btSt.filterMsk2)
    xSel = xSel.*btSt.filterMsk2;
end
if ~isempty(btSt.regMask2)
    xSel = xSel.*btSt.regMask2;
end
if ~isempty(btSt.rmLst2)
    msk00 = ones(numel(ov0.sel),1);
    msk00(btSt.rmLst2) = 0;
    xSel = xSel.*msk00;
end
ov0.sel = xSel>0;
ov(name) = ov0;
setappdata(f,'ov',ov);

ui.movStep(f,[],[],1);

end


