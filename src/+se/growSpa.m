function growSpa(Map,arLst,datOrg)
    [H,W,L,T] = size(datOrg);
    sdLst = label2idx(Map);
    nSeed = numel(sdLst);
    TWs = cell(nSeed,1);
    competition = cell(nSeed,1);
    datVec = reshape(datOrg,[],T);
    curves = zeros(nSeed,T);
    spaLst = cell(nSeed,1);

    % initialization
    for i = 1:nSeed
        [ih,iw,il,it] = ind2sub([H,W,L,T],sdLst{i});
        spaLst{i} = unique(sub2ind([H,W,L],ih,iw,il));
        TWs{i} = min(it):max(it);
        curves(i,:) = mean(datVec(spaLst{i},:),1);
    end

    % relationship
    for i = 1:numel(arLst)
        pix = arLst{i};
        seedLabels = setdiff(Map(pix),0);
        for j = 1:numel(seedLabels)
            curLabel = seedLabels(j);
            for k = j+1:numel(seedLabels)
                nLabel = seedLabels(k);
                
                if ~isempty(intersect(TWs{curLabel},TWs{nLabel}))
                    competition{curLabel} = [competition{curLabel};nLabel];
                    competition{nLabel} = [competition{nLabel};curLabel];
                end
            end
        end
    end


    [dx,dy,dz] = se.dirGenerate(80);
    % needGrow
    sz = cellfun(@numel,competition);
    check = sz>0;
    while sum(check)
        for i = 1:nSeed
            if ~check(i)
                continue;
            end
            ihw = spaLst{i};
            
            curCurve = curves(i,:);
            competeCurves = curves(competition{i},:);
            curTw = TWs{i};
            % newBoundary
            [ih,iw,il] = ind2sub([H,W,L],ihw);
            grow = [];
            for k = 1:numel(dx)
                ih0 = max(1,min(H,ih+dx(k)));
                iw0 = max(1,min(W,iw+dy(k)));
                il0 = max(1,min(L,il+dz(k)));
                grow = [grow;sub2ind([H,W,L],ih0,iw0,il0)];
            end
            pixJudge = setdiff(grow,ihw);
            pixCurves = datVec(pixJudge,curTw);
            curCor = corr(pixCurves',curCurve(curTw)');
            otherCor = -inf(numel(pixJudge),1);
            for k = 1:numel(competition{i})
                competeCurve = competeCurves(k,curTw);
                otherCor = max(otherCor,corr(pixCurves',competeCurve'));
            end
            
            pixJudge = pixJudge(curCor>otherCor);
            if isempty(pixJudge)
                check(i) = false;
            end
            spaLst{i} = [spaLst{i};pixJudge];
            curves(i,:) = mean(datVec(spaLst{i},:),1);
        end
    end
    
    
end