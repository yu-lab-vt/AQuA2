function [seLst,seLabel,mergingInfo] = mergingSEbyInfo(evtLst,majorityEvt,mergingInfo,sz,CC,opts)
    H = sz(1);
    W = sz(2);
    T = sz(3);
    tOverlapPar = 0.5;

    N = numel(evtLst);
    neibLst = mergingInfo.neibLst;
    exLstSpa = mergingInfo.exLstSpa;
    delayDif = mergingInfo.delayDif;
    % if detected gap, events cannot merge
    if(isfield(mergingInfo,'gapLst'))
        gapLst = mergingInfo.gapLst;
    else
        gapLst = cell(N,1);
    end
    exLst = cell(N,1);
    seLabel = 1:N;
    
    for iReg = 1:numel(CC)
        labelsInActReg = mergingInfo.labelsInActRegs{iReg};
        
        %% forbidden pairs
        for i = 1:numel(labelsInActReg)
            curLabel = labelsInActReg(i);     
            ex0 = exLstSpa{curLabel};
            validEx0 = true(numel(ex0),1);
            for j = 2:numel(ex0)
                nLabel = ex0(j);
                curTW = majorityEvt{curLabel}.TW;
                nTW = majorityEvt{nLabel}.TW;
                Toverlap = intersect(curTW,nTW);
                tOver1 = numel(Toverlap)/numel(curTW);
                tOver2 = numel(Toverlap)/numel(nTW);
                % if majority overlap in spatial and overlap, think
                % they are same 
                if(tOver1>=tOverlapPar || tOver2>=tOverlapPar)
                    validEx0(j) = false;
                end
            end
            ex0 = ex0(validEx0);
            ex0 = union(ex0,gapLst{curLabel}); % if detected gap, events cannot merge
            for ii = 1:numel(ex0)
                nLabel = ex0(ii);
                exLst{curLabel} = union(exLst{curLabel},nLabel);
                exLst{nLabel} = union(exLst{nLabel},curLabel);
            end
        end
        
        %% delays
        delayMatrix = zeros(numel(labelsInActReg)*numel(labelsInActReg),3);
        nPair = 0;
        for i = 1:numel(labelsInActReg)
            curLabel = labelsInActReg(i);     
            neib0 = neibLst{curLabel};
            neib0 = neib0(neib0>curLabel);
            ex0 = exLst{curLabel};
            ex0 = ex0(ex0>curLabel);
            neib0 = setdiff(neib0,ex0); % the neighbors need to calculate delay
            
%             curMajIhw =  majorityEvt{curLabel}.ihw;
%             curdelays = majorityEvt{curLabel}.delays;
            for j = 1:numel(neib0)
                nLabel = neib0(j);                 
                if(isKey(delayDif{curLabel},nLabel))
                    timeDelay = delayDif{curLabel}(nLabel);
                else
%                     neiMajIhw = majorityEvt{nLabel}.ihw;
%                     % grow from spatial footprint
%                     [curMarginIhw,neiMarginIhw] = getMaginPix(curMajIhw,neiMajIhw,curMajIhw,neiMajIhw,[H,W]);
%                     tmpDelayMap = zeros(H,W);
%                     tmpDelayMap(curMajIhw) = curdelays;
%                     shift1 = round(mean(tmpDelayMap(curMarginIhw)));
% 
%                     tmpDelayMap = zeros(H,W);
%                     tmpDelayMap(neiMajIhw) = majorityEvt{nLabel}.delays;
%                     shift2 = round(mean(tmpDelayMap(neiMarginIhw)));

                    %% previous
%                     rise1 = majorityEvt{curLabel}.tPeak + shift1;
%                     rise2 = majorityEvt{nLabel}.tPeak + shift2;
%                     timeDelay = abs(rise2-rise1);
%                     delayDif{curLabel}(nLabel) = timeDelay;
                    
                    %% new way
                    shift1 = 0; shift2 = 0;
                    curve1 = majorityEvt{curLabel}.curve;
                    curve2 = majorityEvt{nLabel}.curve;
                    timeDelay = se.avgDist(curve1,curve2,majorityEvt{curLabel}.TW+shift1,majorityEvt{nLabel}.TW+shift2);
                    delayDif{curLabel}(nLabel) = timeDelay;
                end
                
                %% ratio
                nPair = nPair + 1;
                delayMatrix(nPair,:) = [double(curLabel),double(nLabel),timeDelay];
            end
        end
        delayMatrix = delayMatrix(1:nPair,:);
        if(isempty(delayMatrix))
            continue;
        end
        
        %% merging
        maxDelay  = opts.maxDelay;
        delayMatrix = delayMatrix(delayMatrix(:,3)<=maxDelay,:);
        
        [~,id] = sort(delayMatrix(:,3));
        delayMatrix = delayMatrix(id,:);
        uLst = cell(N,1);
        for i = 1:N
            uLst{i} = i;
        end
        seL0 = zeros(N,1);
        
        for i = 1:size(delayMatrix,1)
            id1 = delayMatrix(i,1);
            id2 = delayMatrix(i,2);
            id1 = UF_find(seL0,id1);
            id2 = UF_find(seL0,id2);
            ex1 = exLst{id1};
            ex2 = exLst{id2};
            u1 = uLst{id1};
            u2 = uLst{id2};
            
            if(numel(intersect(u1,ex2))==0 && numel(intersect(u2,ex1))==0)
                root = min(id1,id2);
                uLst{root} = union(u1,u2);
                seL0(id1) = root;
                seL0(id2) = root;
                exLst{root} = union(ex1,ex2);
            end
        end
        

        for i = 1:numel(labelsInActReg)
            id = labelsInActReg(i);
            root = UF_find(seL0,id);
            seL0(id) = root;
        end
            
        seLabel(labelsInActReg) = seL0(labelsInActReg);
    end

    [seLabelUnique,ia,ic] = unique(seLabel);
    seLst = cell(numel(seLabelUnique),1);
    for i = 1:numel(evtLst)
       seID = ic(i);
       seLst{seID} = [seLst{seID};evtLst{i}];
       seLabel(i) = seID;
    end    
    
    mergingInfo.delayDif = delayDif;
end
function root = UF_find(labels,id)
   
   if(labels(id)==0 || labels(id)==id)
        root = id;
   else
        root = UF_find(labels,labels(id));
   end
    
end
function [curMarginIhw,neiMarginIhw] = getMaginPix(curIhw,nIhw,curMajIhw,neiMajIhw,sz)
    H = sz(1); W = sz(2);
    dh = [-1,0,1,-1,0,1,-1,0,1];
    dw = [-1,-1,-1,0,0,0,1,1,1];
    minMarSize = 40;
    % neiGrow, curMargin
    curGrow = curIhw;
    curPre = curIhw;
    nGrow = nIhw;
    nPre = nIhw;
    curMarginIhw = intersect(curMajIhw,nGrow);
    while (numel(curMarginIhw)<minMarSize)
        [ih,iw] = ind2sub([H,W],nGrow);
        for i = 1:numel(dh)
            ih0 = max(1,min(H,ih+dh(i)));
            iw0 = max(1,min(W,iw+dw(i)));
            pix = sub2ind([H,W],ih0,iw0);
            nGrow = union(nGrow,pix);
        end
        nGrow = setdiff(nGrow,nPre);
        if(isempty(nGrow)||sum(ismember(curMajIhw,nPre))==numel(curMajIhw))
            break;
        end
        nPre = [nPre;nGrow];
%         curMarginIhw = intersect(curMajIhw,nPre);
        curMarginIhw = [curMarginIhw;intersect(curMajIhw,nGrow)];
    end

    % curGrow, neiMargin
    neiMarginIhw = intersect(curGrow,neiMajIhw);
    while (numel(neiMarginIhw)<minMarSize) 
        [ih,iw] = ind2sub([H,W],curGrow);
        for i = 1:numel(dh)
            ih0 = max(1,min(H,ih+dh(i)));
            iw0 = max(1,min(W,iw+dw(i)));
            pix = sub2ind([H,W],ih0,iw0);
            curGrow = union(curGrow,pix);
        end
        curGrow = setdiff(curGrow,curPre);
        if(isempty(curGrow)||sum(ismember(neiMajIhw,curPre))==numel(neiMajIhw))
            break;
        end
        curPre = [curPre;curGrow];
%         neiMarginIhw = intersect(neiMajIhw,curPre);
        neiMarginIhw = [neiMarginIhw;intersect(neiMajIhw,curGrow)];
    end
end