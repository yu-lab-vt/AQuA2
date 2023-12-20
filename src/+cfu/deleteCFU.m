function deleteCFU(~,~,f)
fh = guidata(f);
tb = fh.evtTable;
cfuInfo1 = getappdata(f,'cfuInfo1');
nCFU1 = size(cfuInfo1,1);
newCFULst = [];
dat = tb.Data;
for ii=1:size(dat,1)
    if dat{ii,1}==0 && dat{ii,2}==1
        newCFULst = [newCFULst;dat{ii,3}];
    end
    if dat{ii,1}==0 && dat{ii,2}==2
        newCFULst = [newCFULst;dat{ii,3}+nCFU1];
    end
end
fh.favCFUs = newCFULst;
guidata(f,fh);
cfu.updtCFUTable(f);
ui.updtCFUint([],[],f,false);
end