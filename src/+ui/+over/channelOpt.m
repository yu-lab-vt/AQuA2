function channelOpt(~,~,f)
    btSt = getappdata(f,'btSt');
    fh = guidata(f);
    btSt.ChannelL = find(strcmp(fh.channelOptionL.Items,fh.channelOptionL.Value));
    btSt.ChannelR = find(strcmp(fh.channelOptionR.Items,fh.channelOptionR.Value));
    setappdata(f,'btSt',btSt);
    ui.movStep(f);

end