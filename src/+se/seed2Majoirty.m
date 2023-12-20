function [mIhw,TW,delays] = seed2Majoirty(ihw0,dFVec,sz,curEvt,t00,t11,opts)
% Modified by Xuelong on 03/23/2023
% convert to 3D version
    H = sz(1); W = sz(2); L = sz(3); T = sz(4);
    if(~exist('delays','var'))
        delays = zeros(numel(ihw0),1);
    end

    [dh,dw,dl] = se.dirGenerate(26); 
    
    % reference curve, normalize.
    refCurve0 = mean(dFVec(ihw0,:),1); % curve
    [noise] = sqrt(mean((refCurve0(2:end) - refCurve0(1:end-1)).^2)/2);
    refCurve0 = refCurve0/noise;

    % the largest time window is t0:t1. seed window is t00:t11
    [ih,iw,il,it] = ind2sub([H,W,L,T],curEvt);
    t0 = min(it);   t1 = max(it);
    [TW,tPeak] = se.getMajorityTem(imgaussfilt(refCurve0,2),t00,t11,t0,t1);

    
    delayMap = nan(H,W,L,'single');
    delayMap(ihw0) = delays;

    %% Temporal downsample
    durOrg = numel(TW);
    t_scl = max(1,round(durOrg/opts.TPatch));
    refCurve = se.myResize(refCurve0(TW),1/t_scl);
    dur = numel(refCurve);
    t00 = TW(1);

    rThr = 0.7; % set 70% correlation as threshold
    ihw = unique(sub2ind([H,W,L],ih,iw,il));
    maxCor = -ones(H,W,L,'single');
    positiveShift_checked = false;
    preshift = 0;
    for shift = [0:dur,-1:-1:-dur]
        tStart = t00 + shift*t_scl;
        tEnd = tStart + durOrg-1;
        if tStart<=0 || tEnd>T
            continue;
        end
        if shift>0 && positiveShift_checked
            continue;
        end
        if shift==-1
           preshift = 0; 
        end

        % find correlated curves under current delay
        curves = dFVec(ihw,tStart:tEnd);
        curves = se.myResize(curves,'Scale',[1,1/t_scl]);
        r = corr(refCurve',curves')';
        select = r>rThr;
        selectPix = ihw(select);
        r = r(select);
        
        % check whether it is the largest correlation under current shift
        select2 = r>maxCor(selectPix);
        selectPix = selectPix(select2); r = r(select2);

        % check continouity
        BW = false(H,W,L);
        BW(selectPix) = true;
        cc = bwconncomp(BW).PixelIdxList;
        BW = false(H,W,L);
        for k = 1:numel(cc)
            curGroup = cc{k};
            [ih0,iw0,il0] = ind2sub([H,W,L],cc{k});
            for j = 1:numel(dh)
                ih1 = max(1,min(ih0 + dh(j),H));
                iw1 = max(1,min(iw0 + dw(j),W));
                il1 = max(1,min(il0 + dl(j),L));
                nGroup = sub2ind([H,W,L],ih1,iw1,il1);
                if ~isempty(find(delayMap(nGroup)==preshift,1)) % connected, and continous
                    BW(curGroup) = true;
                    break;
                end
            end
        end
        select3 = BW(selectPix);
        selectPix = selectPix(select3); r = r(select3);
        maxCor(selectPix) = r;

        % check whether the peaks of those pixels belong to current event
        newAddVox = selectPix + H*W*L*(tPeak + shift*t_scl - 1);
        select1 = ismember(newAddVox,curEvt);
        selectPix = selectPix(select1); %r = r(select1);

        % update
        if isempty(selectPix)
            if ~positiveShift_checked   % finish the positive shift part. Turn to negative ones
                positiveShift_checked = true;
            else
                break;
            end
        end

        delayMap(selectPix) = shift;
        preshift = shift;
    end
    mIhw = find(~isnan(delayMap));


%     %% previous
%     delayMap = nan(H,W);
%     delayMap(ihw0) = delays;
%     refCurve = refCurve0(TW);
%     L = numel(TW);
%     maxtStart = T - L + 1;
%     
%     newAdd = ihw0;
% 
%     tested = false(H,W);
%     tested(ihw0) = true;
%     
%     % correlation threshold
%     corSigThr = 1e-3;
%     n = min(40,L);
%     zscoreThr = -tinv(corSigThr,n-2);
%     tmp = (zscoreThr/sqrt(n-2))^2;
%     rThr = sqrt(tmp/(tmp+1));
%     mIhw = ihw0;    
%     while(1)
%         maxCor = -ones(H,W);
%         delay = zeros(H,W);
%         tPeaks = zeros(H,W);
%         shifts = unique(delayMap(newAdd));
%         candidate = [];
%         for t = 1:numel(shifts)
%             curShiftPixs = newAdd(delayMap(newAdd)==shifts(t));
%             [ih0,iw0] = ind2sub([H,W],curShiftPixs);
%             curNei = [];
%             for i = 1:numel(dw) 
%                 ih = max(1,min(H,ih0+dh(i)));
%                 iw = max(1,min(W,iw0+dw(i)));
%                 curNei = [curNei;sub2ind([H,W],ih,iw)];
%             end
%             curNei = unique(curNei);
%             curNei = curNei(~tested(curNei));
%             candidate = [candidate;curNei];
%             shift = shifts(t) + [-1:1];
%             tStart = TW(1) + shift;
%             tStart = tStart(tStart>0 & tStart<=maxtStart);
%             for j = 1:numel(tStart)
%                 alignCurves = dFVec(curNei,tStart(j):tStart(j)+L-1);
%                 r = corr(refCurve',alignCurves')';
%                 select = r>maxCor(curNei);
%                 selectPix = curNei(select);
%                 maxCor(selectPix) = r(select);
%                 delay(selectPix) = tStart(j)-TW(1);
%                 [~,id] = max(imgaussfilt(dFVec(selectPix,tStart(j):tStart(j)+L-1),[1e-4,1]),[],2);
%                 tPeaks(selectPix) = id +  tStart(j) - 1;
%             end
%         end
%         candidate = unique(candidate);
%         
%         % correlation limitation
%         newAdd = candidate(maxCor(candidate)>rThr);
%         % peak limitation
%         newAddVox = sub2ind([H*W,T],newAdd,tPeaks(newAdd));
%         newAdd = newAdd(ismember(newAddVox,curEvt));
%         
%         % update
%         mIhw = [mIhw;newAdd]; 
%         tested(candidate) = true;
%         delayMap(newAdd) = delay(newAdd);
%         if(isempty(newAdd))
%             break; 
%         end    
%     end
    delays = delayMap(mIhw)*t_scl;
end