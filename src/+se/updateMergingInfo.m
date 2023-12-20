function mergingInfo = updateMergingInfo(evtLst,dF,majorityEvt,mergingInfo)

    [H,W,T] = size(dF);
%     dFVec = reshape(dF,[],T);
    N = numel(evtLst);
    preN = numel(mergingInfo.neibLst);
    checkLst = false(N,1);
    overlap = 0.5;
    
    sourceLst = mergingInfo.sourceLst;
    newEvtLst = mergingInfo.newEvtLst;
    growLst = mergingInfo.growLst;
    
    
    neighborsUpdate = false(N,1);
    
    % update neighbors and delayMatrix
    Map = zeros([H,W,T],'uint16');
    for i=1:numel(evtLst)
        Map(evtLst{i}) = i;
    end

    N = numel(evtLst);
    neibLst = mergingInfo.neibLst;
    exLstSpa = mergingInfo.exLstSpa;
    evtCCLabel = mergingInfo.evtCCLabel;
    labelsInActRegs = mergingInfo.labelsInActRegs;
    
    dh = [-1 0 1 -1 1 -1 0 1];
    dw = [-1 -1 -1 0 0 1 1 1];
    
    %% Part 1: original event update list
    for i = 1:numel(sourceLst)
        curLabel = sourceLst(i);
        preNeibLst = neibLst{curLabel};
        
        neib0 = [];
        pix = evtLst{curLabel};
        [ih,iw,it] = ind2sub([H,W,T],pix);
        % Neighbor events
        for ii=1:numel(dh)
            ih1 = min(max(ih + dh(ii),1),H);
            iw1 = min(max(iw + dw(ii),1),W);
            vox1 = sub2ind([H,W,T],ih1,iw1,it);
            idxSel = setdiff(Map(vox1),[0,curLabel]);
            neib0 = union(neib0,idxSel);
        end
        neibLst{curLabel} = neib0;
        neighborsUpdate(curLabel) = true;
        checkLst(curLabel) = true;
        checkLst(neib0) = true;
        
        notNeiNow = setdiff(preNeibLst,neib0);
        for j = 1:numel(notNeiNow)
           nLabel =  notNeiNow(j);
           neibLst{nLabel} = setdiff(neibLst{nLabel},curLabel);
        end
    end
    
    %% Part 2: new event List    
    for i = 1:numel(newEvtLst)
        curLabel = newEvtLst(i);
        mergingInfo.delayDif{curLabel} = containers.Map('KeyType','double','ValueType','double');
        neib0 = [];
        pix = evtLst{curLabel};
        [ih,iw,it] = ind2sub([H,W,T],pix);
        % Neighbor events
        for ii=1:numel(dh)
            ih1 = min(max(ih + dh(ii),1),H);
            iw1 = min(max(iw + dw(ii),1),W);
            vox1 = sub2ind([H,W,T],ih1,iw1,it);
            idxSel = setdiff(Map(vox1),[0,curLabel]);
            neib0 = union(neib0,idxSel);
        end
        neibLst{curLabel} = neib0;
        neighborsUpdate(curLabel) = true;
        checkLst(curLabel) = true;
        checkLst(neib0) = true;
        
        for j = 1:numel(neib0)
            nLabel = neib0(j);
            if(nLabel<=preN)
                neibLst{nLabel} = union(neibLst{nLabel},curLabel);
            end
        end
        
        ex0 = [curLabel];
        curMajIhw =  majorityEvt{curLabel}.ihw;
        ccLabel = evtCCLabel(curLabel);
        labelsInActReg = labelsInActRegs{ccLabel};
        for j = 1:numel(labelsInActReg)
            nLabel = labelsInActReg(j);
            if(curLabel==nLabel)
                continue;
            end
            
            nMajIhw = majorityEvt{nLabel}.ihw;
            n0 = numel(intersect(curMajIhw,nMajIhw));
            n1 = numel(curMajIhw);
            n2 = numel(nMajIhw);
            if((n0/n1>overlap || n0/n2>overlap))
                if(curLabel<nLabel)
                    ex0 = [ex0;nLabel];
                else
                    exLstSpa{nLabel} = [exLstSpa{nLabel};curLabel];
                end
            end
        end
        exLstSpa{curLabel} = ex0;
    end
    
    %% Part3: some trivial events merged
    for i = 1:numel(growLst)
        curLabel = growLst(i);
        if(~neighborsUpdate(curLabel))
            neib0 = [];
            pix = evtLst{curLabel};
            [ih,iw,it] = ind2sub([H,W,T],pix);
            % Neighbor events
            for ii=1:numel(dh)
                ih1 = min(max(ih + dh(ii),1),H);
                iw1 = min(max(iw + dw(ii),1),W);
                vox1 = sub2ind([H,W,T],ih1,iw1,it);
                idxSel = setdiff(Map(vox1),[0,curLabel]);
                neib0 = union(neib0,idxSel);
            end
            neibLst{curLabel} = neib0;
            checkLst(curLabel) = true;
            checkLst(neib0) = true;
        else
            neib0 = neibLst{curLabel};
        end
        
        preNeibLst = neibLst{curLabel};
        notNeiPre = setdiff(neib0,preNeibLst);
        notNeiPre = notNeiPre(notNeiPre<=preN);
        for j = 1:numel(notNeiPre)
           nLabel =  notNeiPre(j);
           neibLst{nLabel} = union(neibLst{nLabel},curLabel);
        end
    end
    
    % update
    mergingInfo.neibLst = neibLst;
    mergingInfo.exLstSpa = exLstSpa;
    mergingInfo.refineCheckList = checkLst;
end