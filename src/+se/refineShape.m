function [evtLst] = refineShape(datOrg,evtLst)
    [H,W,L,T] = size(datOrg);
    %% refine region shape
    Map = zeros(size(datOrg),'uint16');
    for i = 1:numel(evtLst)
        Map(evtLst{i}) = i;
    end
    eventOccur = sum(Map,[1,2,3])>0;
    [dx,dy,dz] = se.dirGenerate(26);
    for t = 1:T
        if ~eventOccur(t)
            continue;
        end
        curLabels = setdiff(Map(:,:,:,t),0);
        for i = 1:numel(curLabels)
            curLabel = curLabels(i);
            cc = bwconncomp(Map(:,:,:,t) == curLabel);
            cc = cc.PixelIdxList;
            for j = 1:numel(cc)
                pix = cc{j};
                [ih,iw,il] = ind2sub([H,W,T],pix);
                grow = [];
                for k = 1:numel(dx)
                    ih0 = max(1,min(H,ih + dx(k)));
                    iw0 = max(1,min(W,iw + dy(k)));
                    il0 = max(1,min(L,il + dz(k)));
                    grow = [grow;sub2ind([H,W,L],ih0,iw0,il0)];
                end
                boundary = setdiff(grow,pix);
                [uv,~,idx] = unique(Map(boundary+(t-1)*H*W*L));
                labelCnt = accumarray(idx,1);
                [cntMax,id] = max(labelCnt);
                if cntMax > 0.7*numel(boundary) && uv(id)>0
                    Map(pix+(t-1)*H*W*L) = uv(id);
                end
            end
        end
    end
    evtLst = label2idx(Map);
end