function allAllFav(~,~,fCFU)

fh = guidata(fCFU);

cfuInfo1 = getappdata(fCFU,'cfuInfo1');
cfuInfo2 = getappdata(fCFU,'cfuInfo2');
fh.favCFUs = 1:(size(cfuInfo1,1) + size(cfuInfo2,1));
guidata(fCFU,fh);
cfu.updtCFUTable(fCFU);
ui.updtCFUint([],[],fCFU,false);
end