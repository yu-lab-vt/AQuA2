function evtMngrDeleteSel(~,~,f)
fh = guidata(f);
btSt = getappdata(f,'btSt');
tb = fh.evtTable;
dat = tb.Data;
idxGood1 = [];
idxGood2 = [];
for ii=1:size(dat,1)
    if dat{ii,1}==0 && dat{ii,2}==1
        idxGood1 = union(dat{ii,3},idxGood1);
    end
end
for ii=1:size(dat,1)
    if dat{ii,1}==0 && dat{ii,2}==2
        idxGood2 = union(dat{ii,3},idxGood2);
    end
end
btSt.evtMngrMsk1 = idxGood1;
btSt.evtMngrMsk2 = idxGood2;
setappdata(f,'btSt',btSt);
ui.evt.evtMngrRefresh([],[],f);
ui.movStep(f);
end