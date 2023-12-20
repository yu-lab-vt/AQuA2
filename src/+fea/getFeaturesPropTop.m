function ftsLst = getFeaturesPropTop(evtRec,evtLst,ftsLst,opts)
% getFeaturesPropTop extract propagation related features
% dat: single (0 to 1)
% evtMap: single ( integer)
% evtRec: uint8 ( integer)

[H,W,L,T] = size(evtRec);
if L==1
    if ~isfield(opts,'northx')
        northDi = [0,1];
    else
        northDi = [opts.northx,opts.northy];
        northDi = northDi/sqrt(sum(northDi.^2));
    end
end

muPix = opts.spatialRes;
ftsLst.propagation = [];
for ii=1:numel(evtLst)
    if mod(ii,100)==0
        fprintf('%d/%d\n',ii,numel(evtLst))
    end
    pix0 = evtLst{ii};
    [ih,iw,il,it] = ind2sub([H,W,L,T],pix0);
    rgH = max(min(ih)-1,1):min(max(ih)+1,H);
    rgW = max(min(iw)-1,1):min(max(iw)+1,W);
    rgL = max(min(il)-1,1):min(max(il)+1,L);
    rgT = min(it):max(it);
    
    % basic and propagation features
    ih1 = ih-min(rgH)+1;
    iw1 = iw-min(rgW)+1;
    il1 = il-min(rgL)+1;
    it1 = it-min(rgT)+1;
    voxr = zeros(length(rgH),length(rgW),length(rgL),length(rgT),'single');
    pix1 = sub2ind(size(voxr),ih1,iw1,il1,it1);
    voxr(pix1) = single(evtRec(pix0))/255;
    
    if L == 1
        % 2D propagation metric (relative to starting point)
        ftsLst.propagation = fea.getPropagationCentroidQuad(voxr,muPix,ii,ftsLst.propagation,northDi,opts);
    else
        % 3D propagation metric (relative to starting point)
        ftsLst.propagation = fea.getPropagationCentroidQuad3D(voxr,muPix,ii,ftsLst.propagation,opts);
    end
end

end




