function [fg,bg1,bg2] = neighbor_Individual_spa_temp(pix,pixEx,t_scl,dF)
    [H,W,T] = size(dF);
    T0 = floor(T/t_scl);
    [ih,iw,it] = ind2sub([H,W,T0],pix);
    [ihw,~,project] = unique(sub2ind([H,W],ih,iw));
    
    %% avoid spatial overlap
    cnt = 1;
    fg = [];
    bg1 = [];
    bg2 = [];
    
    for i = 1:numel(ihw)
        select = project==i;
        pixCur = pix(select);
        [ih,iw,it] = ind2sub([H,W,T0],pixCur);
        curH = ih(1);
        curW = iw(1);

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
            pixNow = sub2ind([H,W,T],repmat(curH,numel(tNow),1),repmat(curW,numel(tNow),1),tNow);
            
            t_left = [((max(t0-dur,1)-1)*t_scl+1):(t0-1)*t_scl]';
            pixNL = sub2ind([H,W,T],repmat(curH,numel(t_left),1),repmat(curW,numel(t_left),1),t_left);
            pixNL = setdiff(pixNL,pixNow);
            
            t_right = [(t1*t_scl+1):min(t1+dur,T0)*t_scl]';
            pixNR = sub2ind([H,W,T],repmat(curH,numel(t_right),1),repmat(curW,numel(t_right),1),t_right);
            pixNR = setdiff(pixNR,pixNow);
            
            fgNow = se.myResize(dF(pixNow),1/t_scl);
            fg = [fg;fgNow];
            if(~isempty(pixNL))
                bg1Now = se.myResize(dF(pixNL),1/t_scl);
                bg1 = [bg1;bg1Now];
            end
            if(~isempty(pixNR))
                bg2Now = se.myResize(dF(pixNR),1/t_scl);
                bg2 = [bg2;bg2Now];
            end
            cnt = cnt + 1;
        end
    end
    fg = fg*sqrt(t_scl);
    bg1 = bg1*sqrt(t_scl);
    bg2 = bg2*sqrt(t_scl);
    
end