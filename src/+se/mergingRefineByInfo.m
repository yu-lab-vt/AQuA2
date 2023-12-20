function [seLst,evtLst,seLabel,majorityEvt,mergingInfo] = mergingRefineByInfo(evtLst,seLabel,majorityEvt,dFOrg,dFSmoVec,ccRegions,mergingInfo,opts)

    MaxIter = 10;
    if(numel(evtLst)==0)
        seLst = cell(1,0);
        evtLst = cell(1,0);
        seLabel = [];
        majorityEvt = cell(1,0);
        return;
    end
    
    seLst = cell(max(seLabel),1);
    for i = 1:numel(evtLst)
       seID = seLabel(i);
       seLst{seID} = [seLst{seID};evtLst{i}];
    end    
    
    for k = 1:MaxIter
        % split possible superevent
        [evtLst,majorityEvt,mergingInfo,refineWork] = se.refineEvtsByInfo2(evtLst,seLabel,majorityEvt,dFOrg,dFSmoVec,mergingInfo,opts);
        if(~refineWork)
            break;
        end
        % merge
        mergingInfo = se.updateMergingInfo(evtLst,dFOrg,majorityEvt,mergingInfo);
        [seLst,seLabel,mergingInfo] = se.mergingSEbyInfo(evtLst,majorityEvt,mergingInfo,size(dFOrg),ccRegions,opts);
    end
    [evtLst,majorityEvt,mergingInfo,refineWork] = se.refineEvtsCorrectByInfo(evtLst,seLabel,majorityEvt,dFOrg,dFSmoVec,mergingInfo,opts);
end