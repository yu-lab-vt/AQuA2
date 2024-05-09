function winSzAdjust(~,~,fCFU,f, sg)
fh = guidata(fCFU);
if sg == 0
    if str2double(fh.winSz.Value)>fh.sldWinSz.Limits(2)
        fh.sldWinSz.Limits(2) = str2double(fh.winSz.Value);
    end
    fh.sldWinSz.Value = str2double(fh.winSz.Value);
else
    curV = round(fh.sldWinSz.Value);
    fh.sldWinSz.Value = curV;
    fh.winSz.Value = num2str(curV);
    ui.updtCFUcurve([],[],fCFU,f);
end
end