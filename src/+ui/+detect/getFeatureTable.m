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
featureTable1 = fea.getFeatureTable00(fts1,lmkLst,f);

ftsGlo1 = getappdata(f,'ftsGlo1');
featureTableGlo1 = fea.getFeatureTable00(ftsGlo1,lmkLst,f);

if(~opts.singleChannel)
    fts2 = getappdata(f,'fts2');
    featureTable2 = fea.getFeatureTable00(fts2,lmkLst,f);

    ftsGlo2 = getappdata(f,'ftsGlo2');
    featureTableGlo2 = fea.getFeatureTable00(ftsGlo2,lmkLst,f);
else
    featureTable2 = []; featureTableGlo2 = [];
end
setappdata(f,'featureTable1',featureTable1);
setappdata(f,'featureTable2',featureTable2);
setappdata(f,'featureTableGlo1',featureTableGlo1);
setappdata(f,'featureTableGlo2',featureTableGlo2);

end