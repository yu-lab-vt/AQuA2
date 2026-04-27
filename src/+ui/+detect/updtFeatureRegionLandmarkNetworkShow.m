function ftsLst = updtFeatureRegionLandmarkNetworkShow(f,datR,evtLst,ftsLst,gg,nCh,updateRegMask)

if ~exist('updateRegMask','var')
    updateRegMask = true;
end

btSt = getappdata(f,'btSt');
bd = getappdata(f,'bd');
opts = getappdata(f,'opts');

[ftsLst, regLst] = fea.getNetworkFeatures(datR,evtLst,ftsLst,btSt, bd, opts, nCh,gg);

try
    if updateRegMask && ~isempty(regLst)
        regMask = sum(ftsLst.region.cell.memberIdx>0,2);
        if(nCh == 1)
            btSt.regMask1 = regMask;
        else
            btSt.regMask2 = regMask;
        end
        setappdata(f,'btSt',btSt);
    end
end

end

