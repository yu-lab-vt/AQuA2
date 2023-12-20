function [Map] = seedDetect(dF,datOrg,arLst,opts,ff)
% Xuelong Mi 03/22/2023
% 3D version
%% Top-down detect seeds
    Thrs = opts.maxdF1:-opts.step:opts.thrARScl;
    [H,W,L,T] = size(dF);
    scaleRatios = opts.scaleRatios;
    datResize = se.normalizeAndResize(datOrg,opts);
    Map = zeros(size(dF),'uint16');
    nEvt = 1;

    regSz = zeros(numel(arLst),1);
    activeMap = zeros(H,W,L,T,'uint16');
    for i = 1:numel(arLst)
        activeMap(arLst{i}) = i;
        [ih,iw,il,it] = ind2sub([H,W,L,T],arLst{i});
        regSz(i) = numel(unique(sub2ind([H,W,L],ih,iw,il)));
    end
    
    % assign saturation part can always be selected when checking seed
    if opts.maxValueDat1 == 2^opts.BitDepth - 1
        dF(datOrg==1) = inf;
    end

    for k = 1:numel(Thrs)
        if exist('ff','var')&&~isempty(ff)
            waitbar(0.1 + 0.3*k/numel(Thrs),ff);
        end
        
        %% Find candidates
        curThr = Thrs(k);
        selectMap = (dF>curThr) & activeMap>0;
        curRegions = act.bw2Reg(selectMap,opts);
        %% Rough filter
        sz = cellfun(@numel,curRegions);
        curRegions = curRegions(sz>opts.minSize*opts.minDur/3);
        durs = zeros(numel(curRegions),1);
        %% Filter candidate region
        seedCandidate = false(numel(curRegions),1);
        for i = 1:numel(curRegions)
            pix = curRegions{i};
            arLabel = activeMap(pix(1));
            [ih,iw,il,it] = ind2sub([H,W,L,T],pix);
            ihw = unique(sub2ind([H,W,L],ih,iw,il));
            dur = max(it)-min(it)+1;
            durs(i) = dur;
            % second layer filter
            if(dur<opts.minDur || numel(ihw)<max(opts.minSize,regSz(arLabel)*opts.seedSzRatio))
                continue;
            end 
            labels = setdiff(Map(pix),0);

            % if contain no seed, will check significance later
            if(isempty(labels))
                seedCandidate(i) = true;
            end
        end
        
        durs = durs(seedCandidate);
        seedCandidateRegions = curRegions(seedCandidate);
        sigPass = false(numel(seedCandidateRegions),1);
        
        %% Significance test
        for i = 1:numel(seedCandidateRegions)
            pix = seedCandidateRegions{i};
            t_scl = max(1,round(durs(i)/opts.TPatch));  % temporal downsample coefficient
            for j = 1:numel(scaleRatios)
                spa_scl = scaleRatios(j);
                [z_score1,z_score2,t_score1,t_score2] = se.getSeedScore(pix,spa_scl,t_scl,datResize{j},[H,W,L,T]);
                if min([z_score1,z_score2,t_score1,t_score2])>opts.sigThr
                    sigPass(i) = true;
                    break;
                end
            end
        end

        % Update
        seedCandidateRegions = seedCandidateRegions(sigPass);
        for i = 1:numel(seedCandidateRegions)
            Map(seedCandidateRegions{i}) = nEvt;
            nEvt = nEvt + 1;
        end
    end
end