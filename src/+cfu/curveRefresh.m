function curveRefresh(f,cfuLst)
    fh = guidata(f);
    cfuInfo1 = getappdata(f,'cfuInfo1');
    nCFU1 = size(cfuInfo1,1);
    cfuInfo2 = getappdata(f,'cfuInfo2');
    cols1 = getappdata(f,'cols1')/255;
    cols2 = getappdata(f,'cols2')/255;
    ofstGap = 0.3;
    ax = fh.curve;
    % delete existing curves
    hh = findobj(ax,'Type','line');
    delete(hh);
    hh = findobj(ax,'Type','text');
    delete(hh);
    T = numel(cfuInfo1{1,5});
    ax.XLim = [0,T+1];
    for i = 1:numel(cfuLst)
        id = cfuLst(i);
        if id>nCFU1
            id = id - nCFU1;
            x1 = cfuInfo2{id,5};
            col1 = cols2(id,:);
            TW1 = cfuInfo2{id,7};
            nonTW1 = cfuInfo2{id,8};
        else
            x1 = cfuInfo1{id,5};
            col1 = cols1(id,:);
            TW1 = cfuInfo1{id,7};
            nonTW1 = cfuInfo1{id,8};
        end

        x1 = x1 - min(x1);
        x1 = x1/max(x1);
        x1 = x1 - (i-1)*ofstGap;
        x11 = nan(1,T);x12 = nan(1,T);
        x11(TW1) = x1(TW1);x12(nonTW1) = x1(nonTW1);
        line(ax,1:T,x1,'Color',col1,'LineWidth',1);
        line(ax,1:T,x11,'Color',max(0,col1-0.1),'LineWidth',3);
        line(ax,1:T,x12,'Color',[0.8,0.8,0.8],'LineWidth',1);
    end
    ax.YLim = [0.2 - ofstGap*numel(cfuLst),1.2];
end



