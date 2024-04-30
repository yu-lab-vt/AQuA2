function getFeatureTable(f)

bd = getappdata(f,'bd');
opts = getappdata(f,'opts');
if bd.isKey('landmk')
    bd1 = bd('landmk');
    if opts.sz(3)==1
        lmkLst = cell(numel(bd1),1);
        for ii=1:numel(bd1)
            lmkLst{ii} = bd1{ii}{1};
        end
    else
        lmkLst = [];
    end
else
    lmkLst = [];
end

% show in event manager and for exporting
fts1 = getappdata(f,'fts1');
evtLst1 = getappdata(f, 'evt1');
featureTable1 = fea.getFeatureTable00(fts1,evtLst1,lmkLst,f);
if(~opts.singleChannel)
    fts2 = getappdata(f,'fts2');
    evtLst2 = getappdata(f, 'evt2');
    featureTable2 = fea.getFeatureTable00(fts2,evtLst2,lmkLst,f);
else
    featureTable2 = [];
end
setappdata(f,'featureTable1',featureTable1);
setappdata(f,'featureTable2',featureTable2);

end