function [zscoreL,zscoreR] = Individual_Order_Analysis_spa_temp(pix,pixEx,t_scl,dF)
    [H,W,T] = size(dF);
    T0 = floor(T/t_scl);
    [ih,iw,it] = ind2sub([H,W,T0],pix);
    [ihw,~,project] = unique(sub2ind([H,W],ih,iw));
    
    %% avoid spatial overlap
    cnt = 0;
    fgLst = cell(1,numel(ihw)*10);
    bgLst1 = cell(1,numel(ihw)*10);
    bgLst2 = cell(1,numel(ihw)*10);
    
    % find pixels whose duration are same, cluster them, matrix calculation
    % this part could also use parallel
    for i = 1:numel(ihw)
        select = project==i;
        pixCur = pix(select);
        [~,~,it] = ind2sub([H,W,T0],pixCur);
        dif = it(2:end)-it(1:end-1);
        cut = find(dif>1);
        cut = [0;cut;numel(it)];
        for j = 2:numel(cut)
            id0 = cut(j-1)+1;
            id1 = cut(j);
            t0 = it(id0);
            t1 = it(id1);
            dur = t1-t0+1;
            
            tNow = [((t0-1)*t_scl+1):t1*t_scl]';
            pixNow = ihw(i) + (tNow-1)*H*W;
            
            t_left = [((max(t0-dur,1)-1)*t_scl+1):(t0-1)*t_scl]';
            pixNL = ihw(i) + (t_left-1)*H*W;
            
            t_right = [(t1*t_scl+1):min(t1+dur,T0)*t_scl]';
            pixNR = ihw(i) + (t_right-1)*H*W;
            
            cnt = cnt + 1;
            fgLst{cnt} = se.myResize(dF(pixNow),1/t_scl)*sqrt(t_scl);
            if(~isempty(pixNL))
                bgLst1{cnt} = se.myResize(dF(pixNL),1/t_scl)*sqrt(t_scl);
            end
            if(~isempty(pixNR))
                bgLst2{cnt} = se.myResize(dF(pixNR),1/t_scl)*sqrt(t_scl);
            end
        end 
    end
    
    zscoreLres = zeros(cnt,1);
    zscoreRres = zeros(cnt,1);
    for i = 1:numel(fgLst)
        fg = fgLst{i};
        bg = bgLst1{i};
        if(~isempty(bg))
            L = mean(fg)-mean(bg);
            [mu, sigma] = se.ksegments_orderstatistics_fin(fg, bg);
            zscoreLres(i) = (L-mu)/sigma;
        end
        
        % right
        bg = bgLst2{i};
        if(~isempty(bg))
            L = mean(fg)-mean(bg);
            [mu, sigma] = se.ksegments_orderstatistics_fin(fg, bg);
            zscoreRres(i) = (L-mu)/sigma;
        end
    end
    sz = cellfun(@numel,fgLst(1:cnt));
    
    % 1
%     zscoreL = sz*zscoreLres/sqrt(sum(sz.^2));
%     zscoreR = sz*zscoreRres/sqrt(sum(sz.^2));
    
    % 2
    zscoreL = sqrt(sz)*zscoreLres/sqrt(sum(sz));
    zscoreR = sqrt(sz)*zscoreRres/sqrt(sum(sz));
    
    % 3
%     zscoreL = sum(zscoreLres)/sqrt(numel(fgLst));
%     zscoreR = sum(zscoreRres)/sqrt(numel(fgLst));
end