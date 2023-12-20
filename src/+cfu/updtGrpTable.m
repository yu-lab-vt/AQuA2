function updtGrpTable(fCFU,f)

fh = guidata(fCFU);
groupInfo = getappdata(fCFU,'groupInfo');
% '','Group Index','CFU number in Group','CFU indexes in it'
tb = fh.groupTable;
dat = cell(size(groupInfo,1),4);

for ii=1:size(groupInfo,1)
    dat{ii,1} = false;
    dat{ii,2} = ii;
    dat{ii,3} = numel(groupInfo{ii,2});
    dat{ii,4} = mat2str(groupInfo{ii,2});
end
tb.Data = dat;
end