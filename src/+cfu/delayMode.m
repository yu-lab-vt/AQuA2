function delayMode(~,~,fCFU,f)
    fh = guidata(fCFU);    
    if(fh.delayMode)
        col = getappdata(f,'col');
        fh.delayButton.BackgroundColor = col;
        fh.delayMode = ~fh.delayMode;
    else
        fh.delayButton.BackgroundColor = [0.8,0.8,0.8];
        fh.delayMode = ~fh.delayMode;
    end
    guidata(fCFU,fh);
    ui.updtCFUint([],[],fCFU,false);
end