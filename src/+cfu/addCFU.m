function addCFU(~,~,fCFU,ch)

fh = guidata(fCFU);

cfuInfo1 = getappdata(fCFU,'cfuInfo1'); nCFU1 = size(cfuInfo1,1);
cfuInfo2 = getappdata(fCFU,'cfuInfo2'); nCFU2 = size(cfuInfo2,1);

if ch==1
    addCFU = round(str2double(fh.toolsAddEvt1.Value));
    if ~(addCFU>=1 && addCFU<=nCFU1)
        addCFU = [];
    end
else
    addCFU = round(str2double(fh.toolsAddEvt2.Value));
    if ~(addCFU>=1 && addCFU<=nCFU2)
        addCFU = [];
    else
        addCFU = addCFU + nCFU1;
    end
end

if ~ismember(addCFU,fh.favCFUs)
    fh.favCFUs = [fh.favCFUs;addCFU];
end

guidata(fCFU,fh);
cfu.updtCFUTable(fCFU);
end