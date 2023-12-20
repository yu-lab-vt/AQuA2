function [F0] = baselineLinearEstimate(datIn,cut,movAvgWin)
    % 03/22/2023 Xuelong
    % non-valid is to show the region caused by registration edges
    % grow 5 time points for nan valid part in temporal
    [H,W,L,T] = size(datIn);
    F0 = movmean(datIn,movAvgWin,4,'omitnan');
    F0(isnan(datIn)) = nan;
    F0 = reshape(F0,[],T);
    step = round(0.5*cut);
    maxV = max(datIn(:));

    nSegment = max(1,ceil(T/step)-1);
    minPosition = zeros(H*W*L,nSegment);
    for k = 1:nSegment
%         if(exist('ff','var')&&~isempty(ff))
%             waitbar(0.25*k/nSegment,ff);
%         end
        t0 = 1 + (k-1)*step;
        t1 = min(T,t0+cut);
        [~,curP] = min(F0(:,t0:t1),[],2);
        minPosition(:,k) = curP+t0-1;
    end
    
%     toc;
    for i = 1:H*W*L
        curP = unique(minPosition(i,:));
        value = F0(i,curP);
        curP = curP(~isnan(value));
        value = value(~isnan(value));
        nMin = numel(value);
        curve = zeros(1,T);
        if(nMin==0)
            % all nonValid
            curve = maxV;
        else
           % first part
            curve(1:curP(1)) = value(1);
            % end part
            curve(curP(nMin):T) = value(nMin);
            % middle part
            for k = 1:nMin-1
                mt1 = curP(k);
                mt2 = curP(k+1);
                curve(mt1:mt2) = value(k) + (value(k+1)-value(k))/(mt2-mt1)*[0:mt2-mt1]; 
            end
        end
        F0(i,:) = curve;
    end
    
    F0(isnan(datIn)) = maxV;
    F0 = reshape(F0,[H,W,L,T]);
end