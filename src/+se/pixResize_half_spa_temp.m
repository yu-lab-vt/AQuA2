function [pixChange] = pixResize_half_spa_temp(pix,ratio,t_scl,H,W,T)
    % position in resize data
    [ih,iw,it] = ind2sub([H,W,T],pix);
    ih = ceil(ih/ratio);
    iw = ceil(iw/ratio);
    it = ceil(it/t_scl);
    
    H0 = floor(H/ratio);
    W0 = floor(W/ratio);
    T0 = floor(T/t_scl);
    
    select = ih<=H0 & iw<=W0 & it<=T0;
    pix = sub2ind([H0,W0,T],ih(select),iw(select),it(select));
    [C,~,ic] = unique(pix);
    a_counts = accumarray(ic,1);
    pixChange = C(a_counts>ratio*ratio*t_scl/2);
end