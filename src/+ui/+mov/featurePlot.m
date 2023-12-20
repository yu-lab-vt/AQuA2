function featurePlot(~,~,f)
    g = uifigure('Name','Features','MenuBar','none','Toolbar','none',...
        'NumberTitle','off','Visible','on','Position',[450,260,1000,650]);
    
    gSetting = uigridlayout(g,'Padding',[0,5,0,5],'ColumnWidth',{300,'1x'},'RowHeight',{'1x'},'ColumnSpacing',0,'RowSpacing',5);
    gSetting1 = uigridlayout(gSetting,'Padding',[0,0,0,0],'ColumnWidth',{'1x'},'RowHeight',{20,20,20,20,20,20,75},'ColumnSpacing',0,'RowSpacing',5);

    featureTable1 = getappdata(f,'featureTable1');
    uilabel(gSetting1,'Text','Feature Selection','HorizontalAlignment','center');
    uidropdown(gSetting1,'Items',featureTable1.Properties.RowNames,'Tag','featureSelection');
    uilabel(gSetting1,'Text','Plot Selection','HorizontalAlignment','center');
    uidropdown(gSetting1,'Items',{'BoxPlot','Histogram'},'Tag','type');
    uilabel(gSetting1,'Text','Channel Selection','HorizontalAlignment','center');
    uidropdown(gSetting1,'Items',{'Both Channels','Channel 1','Channel 2'},'Tag','channelSelection');
    bDrawBt = uigridlayout(gSetting1,'Padding',[0,0,0,30],'ColumnWidth',{'1x','1x'},'RowHeight',{'1x','1x'},'RowSpacing',5,'ColumnSpacing',5);
    uibutton(bDrawBt,'push','Text','Features of all events','ButtonPushedFcn',{@update,f,g,0});
    uibutton(bDrawBt,'push','Text','Features of filtered events','ButtonPushedFcn',{@update,f,g,1});
    uibutton(bDrawBt,'push','Text','Features of favorite events','ButtonPushedFcn',{@update,f,g,2});
    axes('Parent',gSetting,'Tag','ax');

    gh = guihandles(g);
    guidata(g,gh);
end
function update(~,~,f,g,stg)
    gh = guidata(g);
    id = find(strcmp(gh.featureSelection.Value,gh.featureSelection.Items));
    ch = find(strcmp(gh.channelSelection.Value,gh.channelSelection.Items));
    btSt = getappdata(f,'btSt');
    switch ch
        case 1
            featureTable1 = table2array(getappdata(f,'featureTable1'));
            switch stg
                case 0
                    x = cell2mat(featureTable1(id,:));
                case 1
                    x = cell2mat(featureTable1(id,btSt.filterMsk1));
                case 2               
                    x = cell2mat(featureTable1(id,btSt.evtMngrMsk1));
            end
            try
                featureTable2 = table2array(getappdata(f,'featureTable2'));
                switch stg
                    case 0
                        x = [x,cell2mat(featureTable2(id,:))];
                    case 1
                        x = [x,cell2mat(featureTable2(id,btSt.filterMsk2))];
                    case 2               
                        x = [x,cell2mat(featureTable2(id,btSt.evtMngrMsk2))];
                end
            end
        case 2
            featureTable1 = table2array(getappdata(f,'featureTable1'));
            switch stg
                case 0
                    x = cell2mat(featureTable1(id,:));
                case 1
                    x = cell2mat(featureTable1(id,btSt.filterMsk1));
                case 2               
                    x = cell2mat(featureTable1(id,btSt.evtMngrMsk1));
            end
        case 3
            featureTable2 = table2array(getappdata(f,'featureTable2'));
            switch stg
                case 0
                    x = [x,cell2mat(featureTable2(id,:))];
                case 1
                    x = [x,cell2mat(featureTable2(id,btSt.filterMsk2))];
                case 2               
                    x = [x,cell2mat(featureTable2(id,btSt.evtMngrMsk2))];
            end
    end
    cla(gh.ax);
    if strcmp(gh.type.Value,'BoxPlot')
        boxplot(gh.ax,x);
    else
        histogram(gh.ax,x);
%         xlim(gh.ax,[min(x)-0.01,max(x)+0.01]);
    end
    xlabel(gh.ax,'Selected feature');
end