function evtMngrShowCurve(~,~,f)
fh = guidata(f);
tb = fh.evtTable;
dat = tb.Data;
idxGood = [];
channels = [];
for ii=1:size(dat,1)
    if dat{ii,1}==1
        idxGood = [idxGood;dat{ii,3}];
        channels = [channels;dat{ii,2}];
    end
end
if ~isempty(idxGood)
    evtLst1 = idxGood(channels==1);
    evtLst2 = idxGood(channels==2);
    ui.evt.curveRefresh([],[],f,evtLst1,evtLst2);
end
end