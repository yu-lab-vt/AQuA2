function [mergingInfo,majorityEvt] = createMergingInfo(evtLst,majorityEvt,ccRegions,sz,opts)
% ----------- Modified by Xuelong Mi, 03/23/2023 -----------
% convert to 3D
    if ~isfield(opts,'spaMergeDist')
        opts.spaMergeDist = 0;
    end
    H = sz(1); W = sz(2); L = sz(3); T = sz(4);
    N = numel(evtLst);
    
    %% get neighbor relation
    Map = zeros([H,W,L,T],'uint16');
    for i=1:numel(evtLst)
        Map(evtLst{i}) = i;
    end
    
    [dh,dw,dl] = se.dirGenerate(26);
    neibLst = cell(N,1);
    delayDif = cell(N,1);
    evtCCLabel = zeros(N,1);
    labelsInActRegs = cell(numel(ccRegions),1);

    for i = 1:N
        pix = evtLst{i};
        round = 0;
        newAdd = pix;
        curGrow = pix;
        while round<=2*opts.spaMergeDist
            % Connected edge
            [ih,iw,il,it] = ind2sub([H,W,L,T],newAdd);
            newAdd = [];
            for ii=1:numel(dh)
                ih1 = min(max(ih + dh(ii),1),H);
                iw1 = min(max(iw + dw(ii),1),W);
                il1 = min(max(il + dl(ii),1),L);
                vox1 = sub2ind([H,W,L,T],ih1,iw1,il1,it);
                newAdd = [newAdd;vox1];
            end
            newAdd = setdiff(newAdd,curGrow);
            curGrow = [curGrow;newAdd];
            round = round + 1;
        end
        neibLst{i} = setdiff(Map(curGrow),[0,i]);
    end
    
    %% get the corresponding relation between actReg and event
    for iReg = 1:numel(ccRegions)
        labelsInActReg = setdiff(Map(ccRegions{iReg}),0);
        labelsInActRegs{iReg} = labelsInActReg;
        evtCCLabel(labelsInActReg) = iReg;
    end
    
    %% create delay map
    for i = 1:N
        delayDif{i} = containers.Map('KeyType','double','ValueType','double');
    end
    
    mergingInfo.neibLst = neibLst;
    mergingInfo.delayDif = delayDif;
    mergingInfo.evtCCLabel = evtCCLabel;
    mergingInfo.labelsInActRegs = labelsInActRegs;
end