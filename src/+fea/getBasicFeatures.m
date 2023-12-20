function ftsBase = getBasicFeatures(voli0,muPerPix,nEvt,ftsBase)
% getFeatures extract local features from events

% basic features
ftsBase.map{nEvt} = voli0;

if size(voli0,3)==1
    cc = regionprops(voli0,'Area','Perimeter');
    ftsBase.area(nEvt) = sum([cc.Area])*muPerPix*muPerPix;
    ftsBase.peri(nEvt) = sum([cc.Perimeter])*muPerPix;
    ftsBase.circMetric(nEvt) = 4*pi*ftsBase.area(nEvt)/(ftsBase.peri(nEvt))^2;
else
    cc = regionprops3(voli0,'Volume','SurfaceArea');
    ftsBase.area(nEvt) = sum([cc.Volume])*muPerPix*muPerPix*muPerPix;
    ftsBase.surf(nEvt) = sum([cc.SurfaceArea])*muPerPix*muPerPix;
    ftsBase.circMetric(nEvt) = pi^(1/3)*(6*ftsBase.area(nEvt))^(2/3)/sum(cc.SurfaceArea);
end
end









