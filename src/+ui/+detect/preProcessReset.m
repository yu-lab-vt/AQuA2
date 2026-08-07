function preProcessReset(~,~,f)
% preProcessReset restores the loaded raw movie for another preprocessing trial.

fh = guidata(f);
datRaw1 = getappdata(f,'datRaw1');
datRaw2 = getappdata(f,'datRaw2');
if isempty(datRaw1)
    uialert(f,'The raw movie is not available in this session.','Reset to raw');
    return
end

opts = getappdata(f,'opts');
rawRange = getappdata(f,'preRawRange');
if ~isempty(rawRange)
    rangeFields = fieldnames(rawRange);
    for ii = 1:numel(rangeFields)
        opts.(rangeFields{ii}) = rawRange.(rangeFields{ii});
    end
end
opts.alreadyProprecess = false;
opts.sz = size(datRaw1);

setappdata(f,'datOrg1',datRaw1);
setappdata(f,'datOrg2',datRaw2);
setappdata(f,'preSetting',[]);
setappdata(f,'dF1',[]);
setappdata(f,'dF2',[]);
setappdata(f,'opts',opts);

scl = getappdata(f,'scl');
scl.min = double(min(datRaw1(:)));
scl.max = double(max(datRaw1(:)));
scl.hrg = [1,size(datRaw1,1)];
scl.wrg = [1,size(datRaw1,2)];
scl.lrg = [1,size(datRaw1,3)];
setappdata(f,'scl',scl);

fh.averPro1 = mean(datRaw1,4);
fh.maxPro1 = max(datRaw1,[],4);
fh.averPro2 = mean(datRaw2,4);
fh.maxPro2 = max(datRaw2,[],4);
fh.movLType.Value = 'Raw';
fh.movRType.Value = 'Raw';
guidata(f,fh);

btSt = getappdata(f,'btSt');
btSt.leftView = 'Raw';
btSt.rightView = 'Raw';
setappdata(f,'btSt',btSt);
ui.mov.movViewSel([],[],f);

disp('Preprocessing reset to raw data.');
end
