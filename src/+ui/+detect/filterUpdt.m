function filterUpdt(~,~,f)
% filterInit initialize filtering table

fh = guidata(f);
tb = fh.filterTable;
btSt = getappdata(f,'btSt');
fCmd = btSt.ftsCmd;

%% channel 1
fts = getappdata(f,'fts1');
nEvt = numel(fts.basic.area);
xSel = true(nEvt,1);

for ii=1:numel(fCmd)
    s0 = tb.Data{ii,1};
    if s0==0
        continue
    end
    xmin = tb.Data{ii,3};
    xmax = tb.Data{ii,4};
    if ~isnumeric(xmin)
        try
            xmin = str2double(xmin);
            xmax = str2double(xmax);
        catch
            return
        end
    end
    cmd0 = ['f0=',fCmd{ii},';'];
    eval(cmd0);
    xSel(isnan(f0)) = false;
    xSel(f0<xmin | f0>xmax) = false;
end
btSt.filterMsk1 = xSel;

%% channel 2
fts = getappdata(f,'fts2');
if (~isempty(fts))
    nEvt = numel(fts.basic.area);
    xSel = true(nEvt,1);

    for ii=1:numel(fCmd)
        s0 = tb.Data{ii,1};
        if s0==0
            continue
        end
        xmin = tb.Data{ii,3};
        xmax = tb.Data{ii,4};
        if ~isnumeric(xmin)
            try
                xmin = str2double(xmin);
                xmax = str2double(xmax);
            catch
                return
            end
        end
        cmd0 = ['f0=',fCmd{ii},';'];
        eval(cmd0);
        xSel(isnan(f0)) = false;
        xSel(f0<xmin | f0>xmax) = false;
    end
    btSt.filterMsk2 = xSel;
end
setappdata(f,'btSt',btSt);
ui.over.updtEvtOvShowLst([],[],f);

end

