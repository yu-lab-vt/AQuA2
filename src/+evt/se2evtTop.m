function [riseLst,datR,evtLst,seLst] = se2evtTop(dF,seLst,svLst,seLabel,majorInfo,opts,ff)
    % Modified by Xuelong 02/24/2023
    % evtTop super voxels to super events and optionally, to events

    gaptxx = opts.gapExt;
    [H,W,L,T] = size(dF);
    seMap = zeros(H,W,L,T,'uint16');
    for i = 1:numel(seLst)
       seMap(seLst{i})  = i;
    end
    
    % super event to events
    fprintf('Detecting events ...\n')
    riseLst = cell(0);
    datR = zeros(H,W,L,T,'uint8');    % brightness for overlay
    datL = zeros(H,W,L,T,'uint16');   % evtMap
    nEvt = 0;
    for nn =  1:numel(seLst)
        se0 = seLst{nn};
        fprintf('SE %d \n',nn)
        if exist('ff','var')&& ~isempty(ff)
            waitbar(0.1+nn/numel(seLst)*0.9,ff);
        end
        
        % super event pixel transform
        [ih0,iw0,il0,it0] = ind2sub([H,W,L,T],se0);
        rgh = min(ih0):max(ih0);  H0 = numel(rgh);
        rgw = min(iw0):max(iw0);  W0 = numel(rgw);
        rgl = min(il0):max(il0);  L0 = numel(rgl);
        gapt = min(max(it0)-min(it0),gaptxx);
        rgt = max(min(it0)-gapt,1):min(max(it0)+gapt,T); T0 = numel(rgt);
        ihw0 = unique(sub2ind([H0,W0,L0],ih0-min(rgh)+1,iw0-min(rgw)+1,il0-min(rgl)+1));
        
        % sub event pixel transform
        svLabels = find(seLabel==nn);
        superVoxels = cell(numel(svLabels),1);
        major0 = majorInfo(svLabels);
        for k = 1:numel(svLabels)
           pix =  svLst{svLabels(k)};
           [ih,iw,il,it] = ind2sub([H,W,L,T],pix);
           ih = ih - min(rgh) + 1;
           iw = iw - min(rgw) + 1;
           il = il - min(rgl) + 1;
           it = it - min(rgt) + 1;
           superVoxels{k} = sub2ind([H0,W0,L0,T0],ih,iw,il,it);
           TW0 = major0{k}.TW;
%            TW0 = max(min(rgt),min(TW0)):min(max(rgt),max(TW0));           
           TW0 = TW0 - min(rgt) + 1;
           major0{k}.TW = TW0;
           mIhw = major0{k}.ihw;
           if(numel(mIhw)<opts.minSize)
               mIhw = [];
           end
           [mIh,mIw,mIl] = ind2sub([H,W,L],mIhw);
           mIh = mIh - min(rgh) + 1;
           mIw = mIw - min(rgw) + 1;
           mIl = mIl - min(rgl) + 1;
           major0{k}.ihw = sub2ind([H0,W0,L0],mIh,mIw,mIl);
        end
        
        dF0 = dF(rgh,rgw,rgl,rgt);
        seMap0 = seMap(rgh,rgw,rgl,rgt);
         [evtRecon,evtL,dlyMaps,nEvt0,svLabel] = evt.se2evt(...
            dF0,seMap0,nn,ihw0,rgt,superVoxels,major0,opts);   
        riseLst = evt.addToRisingMap(riseLst,evtL,dlyMaps,nEvt,rgh,rgw,rgl);    % update rising time map
        
        %% update
        % if extend some events
        seMap0(evtL>0) = nn;
        seMap(rgh,rgw,rgl,rgt) = seMap0;
        
        datR(rgh,rgw,rgl,rgt) = max(datR(rgh,rgw,rgl,rgt),uint8(evtRecon*255));
        evtL(evtL>0) = evtL(evtL>0)+nEvt;
        datL(rgh,rgw,rgl,rgt) = max(datL(rgh,rgw,rgl,rgt),evtL);           
        nEvt = nEvt + nEvt0;
    end
    
    evtLst = label2idx(datL);    
end



