function flow2(~,evtDat,f)
%% the function of RunAllSteps

% delete(gcp('nocreate'));

fh = guidata(f);
ui.detect.preProcessRun([],[],f);
if(~isempty(getappdata(f,'datCorrect1')))
    setappdata(f,'datOrg1',getappdata(f,'datCorrect1'));
    rmappdata(f,'datCorrect1');
    setappdata(f,'datOrg2',getappdata(f,'datCorrect2'));
    rmappdata(f,'datCorrect2');
end
fh.registrateCorrect.Enable = 'off';
fh.bleachCorrect.Enable = 'off';

ui.detect.actRun([],[],f);

ui.detect.phaseRun([],[],f);

ui.detect.evtRun([],[],f);

ui.detect.gloRun([],[],f);

ui.detect.feaRun([],[],f);

% controls
fh.deOutBack.Visible = 'on';
fh.deOutRun.Text = 'Extract';
fh.deOutNext.Text = 'CFU detect';

fh.deOutTab.SelectedTab = fh.deOutTab.Children(end);
opts = getappdata(f,'opts');
opts.enableTab = numel(fh.deOutTab.Children)+1;

for i = 1:numel(fh.deOutTab.Children)
    fh.deOutTab.Children(i).ForegroundColor = [0,0,0];
end

setappdata(f,'opts',opts);

end


