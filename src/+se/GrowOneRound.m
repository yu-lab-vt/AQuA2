function ihw1 = GrowOneRound(ihw,H,W)
    [ih,iw] = ind2sub([H,W],ihw);
    dw = [-1,-1,-1,0,0,0,1,1,1];
    dh = [-1,0,1,-1,0,1,-1,0,1];
    
    ihw1 = [];
%     for j = 1:2
        for i = 1:numel(dw)
            ih0 = min(H,max(1,ih+dh(i)));
            iw0 = min(W,max(1,iw+dw(i)));
            curihw = sub2ind([H,W],ih0,iw0);
            ihw1 = union(ihw1,curihw);
        end
%     end

    

end