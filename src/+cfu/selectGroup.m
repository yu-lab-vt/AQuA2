function selectGroup(~,evtDat,fCFU,f)
    try
        idxNow = evtDat.Indices(1,1);
    catch
        return
    end

    fh = guidata(fCFU); 
    fh.selectCFUs = [];
    
    dat = fh.groupTable.Data;
    
    if(dat{idxNow,1})
        fh.groupShow = 0;
        dat{idxNow,1} = false;
        col = getappdata(f,'col');
        fh.delayButton.BackgroundColor = col;
        fh.delayButton.Enable = 'off';
        fh.delayMode = false;
    else
        if(fh.groupShow>0)
            dat{fh.groupShow,1} = false;
        end
        fh.groupShow = idxNow;
        dat{idxNow,1} = true;
        fh.delayButton.Enable = 'on';
    end  
    fh.groupTable.Data = dat;
    guidata(fCFU,fh);
    ui.updtCFUint([],[],fCFU,false);
end