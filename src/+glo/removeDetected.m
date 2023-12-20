function dF_glo = removeDetected(dF,evtLst)
% By Xuelong Mi, 04/06/2023
    [H,W,L,T] = size(dF);
    
    evtMap = zeros([H,W,L,T],'uint16');
    for i = 1:numel(evtLst)
        evtMap(evtLst{i}) = i;
    end
    
    select = false([H,W,L,T]);
    select(:,:,:,1:end-1) =  evtMap(:,:,:,1:end-1)>0 & evtMap(:,:,:,2:end)>0 & evtMap(:,:,:,2:end) ~= evtMap(:,:,:,1:end-1);
    dF_glo = dF;
    dF_glo(evtMap>0) = nan;
    dF_glo(select>0) = dF(select);
    dF_glo = reshape(dF_glo,[],T);
    clear evtMap
    clear select
    
    parfor i = 1:size(dF_glo,1)
        curve = dF_glo(i,:);
        TWs = bwconncomp(isnan(curve));
        TWs = TWs.PixelIdxList;
        for k = 1:numel(TWs)
            t0 = TWs{k}(1);
            t1 = TWs{k}(end);
            if t0==1
                curve(1:t1) = curve(t1+1);
            elseif t1==T
                curve(t0:T) = curve(t0-1);
            else
                preV = curve(t0-1);
                nextV = curve(t1+1);
                curve(t0:t1) = preV + (nextV-preV)/(t1-t0+2)*[1:t1-t0+1];
            end
        end
        dF_glo(i,:) = curve;
    end
    dF_glo = reshape(dF_glo,[H,W,L,T]);
end