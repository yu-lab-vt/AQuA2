function [seLst,seLabel,mergingInfo] = mergingSEbyInfo_UpdateSpa(evtLst,majorityEvt,mergingInfo,sz,CC,opts)
    H = sz(1);
    W = sz(2);
    L = sz(3);
    T = sz(4);

    N = numel(evtLst);
    neibLst = mergingInfo.neibLst;
    delayDif = mergingInfo.delayDif;

    % if detected gap, events cannot merge
    spaFoot = cell(N,1);
    for i = 1:N
        spaFoot{i} = majorityEvt{i}.ihw;
    end

    seLabel = 1:N;
    
    for iReg = 1:numel(CC)
        labelsInActReg = mergingInfo.labelsInActRegs{iReg};
        
        %% delays
        delayMatrix = zeros(numel(labelsInActReg)*numel(labelsInActReg),3);
        nPair = 0;
        for i = 1:numel(labelsInActReg)
            curLabel = labelsInActReg(i);     
            neib0 = neibLst{curLabel};
            neib0 = neib0(neib0>curLabel);

            curMajIhw =  majorityEvt{curLabel}.ihw;
            curdelays = majorityEvt{curLabel}.delays;
            for j = 1:numel(neib0)
                nLabel = neib0(j);                 
                if(isKey(delayDif{curLabel},nLabel)) % if already calculated
                    timeDelay = delayDif{curLabel}(nLabel);
                else
                    %% find possible delay from center
                    neiMajIhw = majorityEvt{nLabel}.ihw;
                    [shift1,shift2] = getRelativeDelay(curMajIhw,neiMajIhw,curdelays,majorityEvt{nLabel}.delays,[H,W,L]);
                    
                    %% if not, recalculate. Compare difference.
                    curve1 = majorityEvt{curLabel}.curve;
                    curve2 = majorityEvt{nLabel}.curve;
%                     disp([curLabel,nLabel]);                    
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
        
        %% merging. Nature is hierarchical clustering.
        maxDelay  = opts.maxDelay;
        delayMatrix = delayMatrix(delayMatrix(:,3)<=maxDelay,:);
        
        [~,id] = sort(delayMatrix(:,3));
        delayMatrix = delayMatrix(id,:);
%         uLst = cell(N,1);
%         for i = 1:N
%             uLst{i} = i;
%         end
        seL0 = 1:N;
        
        for i = 1:size(delayMatrix,1)
            id1 = delayMatrix(i,1);
            id2 = delayMatrix(i,2);
            id1 = UF_find(seL0,id1);
            id2 = UF_find(seL0,id2);

            mIhw1 = spaFoot{id1};
            mIhw2 = spaFoot{id2};

            n0 = numel(intersect(mIhw1,mIhw2));
            n1 = numel(mIhw1);
            n2 = numel(mIhw2);

            %large spatial overlap will evidence they do not belong to the same signal.
            if n0/n1<=opts.overlap && n0/n2<=opts.overlap
                if id1<id2
                    seL0(id2) = id1;
                    spaFoot{id1} = union(mIhw1,mIhw2);
                else
                    seL0(id1) = id2;
                    spaFoot{id2} = union(mIhw1,mIhw2);
                end
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
   
   if(labels(id)~=id)
        labels(id) = UF_find(labels,labels(id));
   end
   root = labels(id);
end
function [shift1,shift2] = getRelativeDelay(curMajIhw,neiMajIhw,curdelays,neidelays,sz)
    H = sz(1);W = sz(2); L = sz(3);
    [ih0,iw0,il0] = ind2sub([H,W,L],curMajIhw);
    if sum(curdelays==0)>0
        x0 = mean(ih0(curdelays==0));
        y0 = mean(iw0(curdelays==0));
        z0 = mean(il0(curdelays==0));
    else
        x0 = mean(ih0);
        y0 = mean(iw0);
        z0 = mean(il0);
    end

    [ih1,iw1,il1] = ind2sub([H,W,L],neiMajIhw);
    if sum(neidelays==0)>0
        x1 = mean(ih1(neidelays==0));
        y1 = mean(iw1(neidelays==0));
        z1 = mean(il1(neidelays==0));
    else
        x1 = mean(ih1);
        y1 = mean(iw1);
        z1 = mean(il1);
    end
    
    % 0.8 is just one parameter
    % the furthest pixels in cur region
    dist = [ih0-x0,iw0-y0,il0-z0]*[x1-x0,y1-y0,z1-z0]';
    select1 = dist>=max(dist)*0.8;
    shift1 = round(mean(curdelays(select1)));

    % the furthest pixels in nei region
    dist = [ih1-x1,iw1-y1,il1-z1]*[x0-x1,y0-y1,z0-z1]';
    select2 = dist>=max(dist)*0.8;
    shift2 = round(mean(neidelays(select2)));
end