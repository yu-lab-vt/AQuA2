function evtMngrRefresh(~,~,f)

fh = guidata(f);
btSt = getappdata(f,'btSt');
fts1 = getappdata(f,'fts1');
lst1 = btSt.evtMngrMsk1;
fts2 = getappdata(f,'fts2');
lst2 = btSt.evtMngrMsk2;

% {'','Channel','Index','Frame','Size','Duration','df/f','Decay tau'};
tb = fh.evtTable;
dat = cell(numel(lst1)+numel(lst2),8);

for ii=1:numel(lst1)
    idx00 = lst1(ii);
    dat{ii,1} = false;
    dat{ii,2} = 1;
    dat{ii,3} = idx00;
    dat{ii,4} = fts1.curve.tBegin(idx00);
    dat{ii,5} = fts1.basic.area(idx00);
    if isfield(fts1.curve,'duration')
        dat{ii,6} = fts1.curve.duration(idx00);
    else
        dat{ii,6} = fts1.curve.tEnd(idx00) - fts1.curve.tBegin(idx00);
    end
    dat{ii,7} = fts1.curve.dffMax(idx00);
    dat{ii,8} = fts1.curve.decayTau(idx00);
end

for ii=numel(lst1)+1:numel(lst1)+numel(lst2)
    idx00 = lst2(ii-numel(lst1));
    dat{ii,1} = false;
    dat{ii,2} = 2;
    dat{ii,3} = idx00;
    dat{ii,4} = fts2.curve.tBegin(idx00);
    dat{ii,5} = fts2.basic.area(idx00);
    if isfield(fts2.curve,'duration')
        dat{ii,6} = fts2.curve.duration(idx00);
    else
        dat{ii,6} = fts2.curve.tEnd(idx00) - fts2.curve.tBegin(idx00);
    end
    dat{ii,7} = fts2.curve.dffMax(idx00);
    dat{ii,8} = fts2.curve.decayTau(idx00);
end

tb.Data = dat;

% update detailed features
figFav = getappdata(f,'figFav');
if ~isempty(figFav) && isvalid(figFav)
    ui.evt.showDetails([],[],f);
end

end