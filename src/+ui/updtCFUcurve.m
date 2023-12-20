function updtCFUcurve(~,~,fCFU,f)
    fh = guidata(fCFU);
    opts = getappdata(f,'opts');
    cfuInfo1 = getappdata(fCFU,'cfuInfo1');
    cfuInfo2 = getappdata(fCFU,'cfuInfo2');
    sz = opts.sz;
    ofstGap = 0.3;
    selectCFUs = fh.selectCFUs;
%     ax = fh.curve;
    % delete existing curves
%     hh = findobj(ax,'Type','line');
%     delete(hh);
%     hh = findobj(ax,'Type','text');
%     delete(hh);
    T = sz(4);
%     ax.XLim = [0,T+1];
    
    if size(selectCFUs,1) == 2
        figure;
        hold on;
        cols1 = getappdata(fCFU,'cols1')/255;
        cols2 = getappdata(fCFU,'cols2')/255;
        if(selectCFUs(1,1)==1)
            x1 = cfuInfo1{selectCFUs(1,2),5};
            seq1 = cfuInfo1{selectCFUs(1,2),4};
            col1 = cols1(selectCFUs(1,2),:);
            TW1 = cfuInfo1{selectCFUs(1,2),7};
            nonTW1 = cfuInfo1{selectCFUs(1,2),8};
        else
            x1 = cfuInfo2{selectCFUs(1,2),5};
            seq1 = cfuInfo2{selectCFUs(1,2),4};
            col1 = cols2(selectCFUs(1,2),:);
            TW1 = cfuInfo2{selectCFUs(1,2),7};
            nonTW1 = cfuInfo2{selectCFUs(1,2),8};
        end
        x1 = x1 - min(x1);
        x1 = x1/max(x1);
        x11 = nan(1,T);x12 = nan(1,T);
        x11(TW1) = x1(TW1);x12(nonTW1) = x1(nonTW1);
        plot(1:T,x1,'Color',col1,'LineWidth',1);
        plot(1:T,x11,'Color',max(0,col1-0.1),'LineWidth',3);
        plot(1:T,x12,'Color',[0.8,0.8,0.8],'LineWidth',1);
        % draw new curves
        if(selectCFUs(2,1)==1)
            x2 = cfuInfo1{selectCFUs(2,2),5};
            seq2 = cfuInfo1{selectCFUs(2,2),4};
            col2 = cols1(selectCFUs(2,2),:);
            TW2 = cfuInfo1{selectCFUs(2,2),7};
            nonTW2 = cfuInfo1{selectCFUs(2,2),8};
        else
            x2 = cfuInfo2{selectCFUs(2,2),5};
            seq2 = cfuInfo2{selectCFUs(2,2),4};
            col2 = cols2(selectCFUs(2,2),:);
            TW2 = cfuInfo2{selectCFUs(2,2),7};
            nonTW2 = cfuInfo2{selectCFUs(2,2),8};
        end
        x2 = x2 - min(x2);
        x2 = x2/max(x2);
        x2 = x2 + ofstGap;
        x21 = nan(1,T);x22 = nan(1,T);
        x21(TW2) = x2(TW2);x22(nonTW2) = x2(nonTW2);
        plot(1:T,x2,'Color',col2,'LineWidth',1);
        plot(1:T,x21,'Color',max(0,col2-0.1),'LineWidth',3);
        plot(1:T,x22,'Color',[0.8,0.8,0.8],'LineWidth',1);
        ylim([-0.1,1+ofstGap+0.2]);
        
        maxDist = round(fh.sldWinSz.Value);

        [pvalue1] = cfu.calDependency(seq1, seq2,0:maxDist); % condition is the first variable, occurrence is the second.
        [pvalue2] = cfu.calDependency(seq2, seq1,0:maxDist); % condition is the first variable, occurrence is the second.
        txt0 = ['pValue - dependency: ',num2str(min(pvalue1,pvalue2))];
        text(T*0.6,1,txt0);

        fh.selectCFUs = [];
        guidata(fCFU,fh);
    end
end



