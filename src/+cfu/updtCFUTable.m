function updtCFUTable(fCFU)

fh = guidata(fCFU);
favLst = fh.favCFUs;
cfuInfo1 = getappdata(fCFU,'cfuInfo1'); nCFU1 = size(cfuInfo1,1);
cfuInfo2 = getappdata(fCFU,'cfuInfo2');
% {'','Channel','Index','Frame','Size','Duration','df/f','Decay tau'};
tb = fh.evtTable;
dat = cell(numel(favLst),5);

for i=1:numel(favLst)
    id = favLst(i);
    dat{i,1} = false;
    if id>nCFU1
        id = id - nCFU1;
        dat{i,2} = 2;
        dat{i,3} = id;
        dat{i,4} = numel(cfuInfo2{id,2});
        dat{i,5} = mat2str(cfuInfo2{id,2});
    else
        dat{i,2} = 1;
        dat{i,3} = id;
        dat{i,4} = numel(cfuInfo1{id,2});
        dat{i,5} = mat2str(cfuInfo1{id,2});
    end
end
tb.Data = dat;
end