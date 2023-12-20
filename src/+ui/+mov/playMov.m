function playMov(~,~,f)
fh = guidata(f);
% fh.play.Enable = 'off';
try
    pauseTime = max(1/25,1/str2double(fh.playbackRate.Value));
catch
    pauseTime = 0.2;
end
btSt = getappdata(f,'btSt');
btSt.play = 1;
setappdata(f,'btSt',btSt);
n0 = round(fh.sldMov.Value);
scl = getappdata(f,'scl');
for nn=n0:scl.T
    btSt = getappdata(f,'btSt');
    playx = btSt.play;
    if playx==0  % interrupted by pauseMov
        break
    end
    ui.movStep(f,nn);
    fh.sldMov.Value = nn;
    pause(pauseTime);
    if(isfield(fh,'showcurves') && ~isempty(fh.showcurves))
        evtIdx = fh.showcurves(:,1);
        if ~isempty(evtIdx)
            channels = fh.showcurves(:,2);
            evtIdx1 = evtIdx(channels==1);
            evtIdx2 = evtIdx(channels==2);
            ui.evt.curveRefresh([],[],f,evtIdx1,evtIdx2);
        end
    end
end
% fh.play.Enable = 'on';
end