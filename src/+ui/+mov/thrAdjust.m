function thrAdjust(~,~,f,sg)
fh = guidata(f);
opts = getappdata(f,'opts');
if sg == 0
    if str2double(fh.thrArScl.Value)>fh.sldActThr.Limits(2)
        fh.sldActThr.Limits(2) = str2double(fh.thrArScl.Value);
    end
    fh.sldActThr.Value = str2double(fh.thrArScl.Value);
else
    curV = fh.sldActThr.Value;
    curV = round(curV*10)/10;
    fh.sldActThr.Value = curV;
    fh.thrArScl.Value = num2str(curV);
end
fh = guidata(f);
fh.movLType.Value = 'Threshold preview';
if ~opts.singleChannel
    fh.movRType.Value = 'Threshold preview';
end

fh.sbs.Value = 1;
ui.mov.movSideBySide([],[],f);
ui.mov.movViewSel([],[],f);
end