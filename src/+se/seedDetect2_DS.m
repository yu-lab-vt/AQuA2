function [Map,arLst] = seedDetect2_DS(dF,datOrg,arLst,opts,ff)
% Xuelong Mi 04/17/2023
% 3D version
%% Multi-scale Top-down detect seeds
    Thrs = opts.maxdF1:-opts.step:opts.thrARScl;
    scaleRatios = [2,4,8];
    opts.scaleRatios = scaleRatios;
    [H,W,L,T] = size(dF);
    
    % assign saturation part can always be selected when checking seed
    if opts.maxValueDat1 == 2^opts.BitDepth - 1
        dF(datOrg==1) = inf;
    end

    regSz = zeros(numel(arLst),1);
    activeMap = zeros(H,W,L,T,'uint16');
    % active map
    for i = 1:numel(arLst)
        activeMap(arLst{i}) = i;
        [ih,iw,il,~] = ind2sub([H,W,L,T],arLst{i});
        regSz(i) = numel(unique(sub2ind([H,W,L],ih,iw,il)));
    end

    % downsampled data
    validMaps = cell(numel(scaleRatios),1);
    datResize = se.normalizeAndResize(datOrg,opts); % normalized data to do significance test
    dFResize = cell(numel(scaleRatios),1);          % downsampled data to do selection
    H0s = zeros(numel(scaleRatios),1);
    W0s = zeros(numel(scaleRatios),1);
    for j = 1:numel(scaleRatios)
        datResize{j} = reshape(datResize{j},[],T);
%         if j>1
            dFResize{j} = se.myResize(dF,1/scaleRatios(j));
            validMaps{j} = se.myResize(activeMap,1/scaleRatios(j))>0;
%         else
%             dFResize{1} = dF;
%             validMaps{1} = activeMap>0;
%         end
        H0s(j) = ceil(H/scaleRatios(j));
        W0s(j) = ceil(W/scaleRatios(j));
    end

    % seed map
    zscoreMap = zeros(size(dF),'single');

    for k = 1:numel(Thrs)   % threshold
        curThr = Thrs(k);
        if exist('ff','var')&&~isempty(ff)
            waitbar(0.1 + 0.3*k/numel(Thrs),ff);
        end
        for j = 1:numel(scaleRatios)    % downsample rate
            H0 = H0s(j); W0 = W0s(j);
            scaleRatio = scaleRatios(j);
            tmp = repmat(1:scaleRatio,scaleRatio,1);
            tmp = tmp(:)';
            selectMap = dFResize{j}>curThr & validMaps{j};
            curRegions = act.bw2Reg(selectMap,opts);
             %% Rough filter -- for acceleration
            sz = cellfun(@numel,curRegions);
            curRegions = curRegions(sz>opts.minSize/scaleRatio^2*opts.minDur/3);

            for i = 1:numel(curRegions)
                pix = curRegions{i};
                [ih,iw,il,it] = ind2sub([H0,W0,L,T],pix);
                ihw = unique(sub2ind([H0,W0,L],ih,iw,il));
                dur = max(it) - min(it)+1;
                arLabel = activeMap((ih(1)-1)*scaleRatio+1:min(H,ih(1)*scaleRatio),(iw(1)-1)*scaleRatio+1:min(W,iw(1)*scaleRatio),il(1),it(1));
                arLabel = setdiff(arLabel,0); arLabel = arLabel(1);
                %% filter according to size and duration, also check seed detected or not
                if dur<opts.minDur || numel(ihw)<max(opts.minSize,regSz(arLabel)*opts.seedSzRatio)/scaleRatio^2
                    continue;
                end

                % convert back
%                 if j>1
                    ihOrg = repmat((ih-1)*scaleRatio,1,scaleRatio*scaleRatio) + repmat(1:scaleRatio,numel(ih),scaleRatio);
                    iwOrg = repmat((iw-1)*scaleRatio,1,scaleRatio*scaleRatio) + repmat(tmp,numel(ih),1);
                    ilOrg = repmat(il,1,scaleRatio*scaleRatio);
                    itOrg = repmat(it,1,scaleRatio*scaleRatio);
                    select = ihOrg<=H & iwOrg<=W;
                    pixOrg = sub2ind([H,W,L,T],ihOrg(select),iwOrg(select),ilOrg(select),itOrg(select));
%                     pixOrg = pixOrg(activeMap(pixOrg)>0);
%                 else
%                     pixOrg = pix;
%                 end
                if numel(pixOrg)<max(opts.minSize,regSz(arLabel)*opts.seedSzRatio) || ~isempty(find(zscoreMap(pixOrg)>0,1))
                    continue;
                end

                %% calculate significance
                t_scl = max(1,round(dur/opts.TPatch));
%                 [z_score1,z_score2,t_score1,t_score2] = se.getSeedScore_DS(pix,t_scl,datResize{j});
                [z_score1,z_score2,t_score1,t_score2] = se.getSeedScore_DS2(pix,t_scl,datResize{j},[H0,W0,L,T]);
                if min([z_score1,z_score2,t_score1,t_score2])>opts.sigThr
                    %% check seed curve significance
                    curve = mean(datResize{j}(ihw,:),1);
                    hasPeak =  se.curveSignificance(curve,min(it),max(it),opts.sigThr);
                    if hasPeak
                        %% update
                        zscoreMap(pixOrg) = max(min(z_score1,z_score2),zscoreMap(pixOrg));
%                     else
%                         keyboard;
                    end
                end
            end
        end
    end
    toc;
    Map = bwlabeln(imregionalmax(zscoreMap));
    arLst = bwconncomp(Map>0 | activeMap>0);
    arLst = arLst.PixelIdxList;
end