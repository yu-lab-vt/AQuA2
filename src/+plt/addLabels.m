function ov = addLabels(ov,traLstSelect)
    [H,W,~,T] = size(ov);
    for i = 1:numel(traLstSelect)
        [ih,iw,it] = ind2sub([H,W,T],traLstSelect{i});
        tPass = unique(it);
        for k = 1:numel(tPass)
            t = tPass(k);
            select = it==t;
            meanIh = round(mean(ih(select)));
            meanIw = round(mean(iw(select)));
            ov(:,:,:,t) = insertText(ov(:,:,:,t),[meanIw,meanIh],i,'Fontsize',8,'BoxOpacity',0.4,'TextColor','black');
        end
    end
end