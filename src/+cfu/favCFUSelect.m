function favCFUSelect(~,evtDat,f)
    
    try
        idxNow = evtDat.Indices(1,1);
    catch
        return
    end
    
    if isempty(idxNow) || idxNow==0
        return
    end    
    
    fh = guidata(f);
    tb = fh.evtTable;
    dat = tb.Data;
    cfuNow = dat{idxNow,3};
    nCh = dat{idxNow,2};
    cfuInfo1 = getappdata(f,'cfuInfo1'); nCFU1 = size(cfuInfo1,1);
    cfuNow = (nCh-1)*nCFU1 + cfuNow;
    cfu.curveRefresh(f,cfuNow);
end



