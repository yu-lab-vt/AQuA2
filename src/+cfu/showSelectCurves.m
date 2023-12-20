function showSelectCurves(~,~,f)
    
    fh = guidata(f);
    tb = fh.evtTable;
    dat = tb.Data;
    selectCFUs = [];
    cfuInfo1 = getappdata(f,'cfuInfo1'); nCFU1 = size(cfuInfo1,1);
    for i = 1:size(dat,1)
        if dat{i,1}==1 && dat{i,2}==1
            selectCFUs = [selectCFUs;dat{i,3}];
        elseif dat{i,1}==1 && dat{i,2}==2
            selectCFUs = [selectCFUs;dat{i,3}+nCFU1];
        end
    end    
    cfu.curveRefresh(f,selectCFUs);
end



