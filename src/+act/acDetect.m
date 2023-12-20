function [arLst] = acDetect(dF,opts,evtSpatialMask,ch,ff)
% ----------- Modified by Xuelong Mi, 02/09/2023 -----------
% detect active region
    % bottom-up to accelerate
    if ch == 1
        maxdF = opts.maxdF1;
    else
        maxdF = opts.maxdF2;
    end

    if opts.thrARScl>maxdF || (opts.maxSize>=numel(evtSpatialMask) && opts.circularityThr==0)
        % no advanced filter setting, single threshold
        thrs = opts.thrARScl;
    else
        % have advanced filter setting, multiple threshold
        thrs = opts.thrARScl:(maxdF-opts.thrARScl)/10:maxdF;
    end

    [H,W,L,T] = size(dF);
    evtSpatialMask = evtSpatialMask(:);
    dF = reshape(dF,[],T);
    dF(~evtSpatialMask,:) = -1;
    dF = reshape(dF,[H,W,L,T]);
    
    % valid region
    activeMap = zeros(H,W,L,T,'uint16');
    nReg = 0;
    tic;
    for k = 1:numel(thrs)
        thr = thrs(k);
        selectMap = (dF>thr & activeMap==0);
        curRegions = act.bw2Reg(selectMap,opts);
%         disp(numel(curRegions));
        valid = false(numel(curRegions),1);
        parfor i = 1:numel(curRegions)
            pix = curRegions{i};
            [ih,iw,il,it] = ind2sub([H,W,L,T],pix);
            H0 = max(ih) - min(ih) + 1;             ih = ih - min(ih) + 1;
            W0 = max(iw) - min(iw) + 1;             iw = iw - min(iw) + 1;
            L0 = max(il) - min(il) + 1;             il = il - min(il) + 1;
            T0 = max(it) - min(it) + 1;             it = it - min(it) + 1;

            pix0 = sub2ind([H0,W0,L0,T0],ih,iw,il,it);
            curMap = false(H0,W0,L0,T0);
            curMap(pix0) = true;
            curMap = (sum(curMap,4)>opts.compress*T0);
            ihw = find(curMap);
            curSz = numel(ihw);
            
            % size, duration limitation
            if (curSz>opts.maxSize || curSz<opts.minSize || T0<opts.minDur)
               continue; 
            end

            if opts.circularityThr==0
                valid(i) = true;
                continue;
            end

            if L==1
                erodeMap = imerode(curMap,strel('disk',1));
                boundary = curSz - sum(erodeMap(:));
                circularity = 4*pi*curSz/(boundary^2);
            else
                erodeMap = imerode(curMap,strel('sphere',1));
                surface = curSz - sum(erodeMap(:));
                circularity = pi^(1/3)*(6*curSz)^(2/3)/surface;
            end
            
            % circularity limitation
            if(circularity>opts.circularityThr)
                valid(i) = true;
            end
        end

        curRegions = curRegions(valid);
        for i = 1:numel(curRegions)
            activeMap(curRegions{i}) = nReg + i;
        end
        nReg = nReg + numel(curRegions);
        if exist('ff','var')&&~isempty(ff)
            waitbar(k/numel(thrs),ff,'Active region detection ...');
        end
    end
    toc;
    arLst = label2idx(activeMap);
end

