function ftsLst = updtFeatureRegionLandmarkNetworkShow(f,datR,evtLst,ftsLst,gg,nCh)

btSt = getappdata(f,'btSt');
bd = getappdata(f,'bd');
opts = getappdata(f,'opts');

[ftsLst, regLst] = fea.getNetworkFeatures(datR,evtLst,ftsLst,btSt, bd, opts, nCh,gg);

try
    if ~isempty(regLst)
        regMask = sum(ftsLst.region.cell.memberIdx>0,2);
    end
    if(nCh == 1)
        btSt.regMask1 = regMask;
    else
        btSt.regMask2 = regMask;
    end
    setappdata(f,'btSt',btSt);
end

end


