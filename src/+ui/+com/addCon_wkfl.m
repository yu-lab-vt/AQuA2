function addCon_wkfl(f,pWkfl)
    
    % workflow panels ----
    bWkfl = uigridlayout(pWkfl,'Tag','bWkfl','Padding',[0,0,0,0],'ColumnWidth',{'1x'},'RowHeight',{100,340,228,100,52,'1x'},'RowSpacing',5);
    pDraw = uipanel(bWkfl,'Tag','pDraw');
    pDeOut = uipanel(bWkfl,'Tag','pDeOut');
    pFilter = uipanel(bWkfl,'Tag','pFilter');
    pExport = uipanel(bWkfl,'Tag','pExport');
    pSys = uipanel('Parent',bWkfl,'Tag','pSys');
    
    % draw regions ----
    bDraw = uigridlayout(pDraw,'Padding',[0,5,0,0],'ColumnWidth',{'1x'},'RowHeight',{20,'1x',20},'ColumnSpacing',0,'RowSpacing',5);
    uilabel(bDraw,'Text','Direction, regions, landmarks','BackgroundColor',[0 0.3 0.6],'FontColor','white');
    gDraw = uigridlayout(bDraw,'Tag','drawRegButtons','Padding',[0,0,0,0],'ColumnWidth',{'1x',20,20,20,50,40,40},'RowHeight',{'1x','1x'},'ColumnSpacing',0,'RowSpacing',5);
    uilabel(gDraw,'Text','  Cell boundary');
    uibutton(gDraw,'push','Text','+','Tag','AddCell','ButtonPushedFcn',...
        {@ui.mov.updtCursorFunMov,f,'add','cell'},'Interruptible','off','BusyAction','cancel');
    uibutton(gDraw,'push','Text','-','Tag','RmCell',...
    'ButtonPushedFcn',{@ui.mov.updtCursorFunMov,f,'rm','cell'});
    uibutton(gDraw,'push','Text','->','Tag','DragCell','ButtonPushedFcn',...
        {@ui.mov.updtCursorFunMov,f,'drag','cell'},'Interruptible','off','BusyAction','cancel');
    uibutton(gDraw,'push','Text','Name','Tag','NameCell',...
    'ButtonPushedFcn',{@ui.mov.updtCursorFunMov,f,'name','cell'});
    uibutton(gDraw,'push','Text','Save',...
    'ButtonPushedFcn',{@ui.mov.regionSL,f,'save','cell'});
    uibutton(gDraw,'push','Text','Load',...
    'ButtonPushedFcn',{@ui.mov.regionSL,f,'load','cell'});
    uilabel(gDraw,'Text','  Landmark(soma)');
    uibutton(gDraw,'push','Text','+','Tag','AddLm','ButtonPushedFcn',...
        {@ui.mov.updtCursorFunMov,f,'add','landmk'},'Interruptible','off','BusyAction','cancel');
    uibutton(gDraw,'push','Text','-','Tag','RmLm',...
    'ButtonPushedFcn',{@ui.mov.updtCursorFunMov,f,'rm','landmk'});
    uibutton(gDraw,'push','Text','->','Tag','DragLm','ButtonPushedFcn',...
        {@ui.mov.updtCursorFunMov,f,'drag','landmk'},'Interruptible','off','BusyAction','cancel');
    uibutton(gDraw,'push','Text','Name','Tag','NameLm',...
    'ButtonPushedFcn',{@ui.mov.updtCursorFunMov,f,'name','landmk'});
    uibutton(gDraw,'push','Text','Save',...
    'ButtonPushedFcn',{@ui.mov.regionSL,f,'save','landmk'});
    uibutton(gDraw,'push','Text','Load',...
    'ButtonPushedFcn',{@ui.mov.regionSL,f,'load','landmk'});

    bDrawBt = uigridlayout(bDraw,'Padding',[5,0,5,0],'ColumnWidth',{'fit','fit','fit'},'RowHeight',{'1x'},'ColumnSpacing',10,'RowSpacing',5);
    uibutton(bDrawBt,'push','Text','Draw anterior','Tag','drawNorth','ButtonPushedFcn',...
        {@ui.mov.drawReg,f,'arrow','diNorth'},'Interruptible','off','BusyAction','cancel');
    uibutton(bDrawBt,'push','Text','Mask builder',...
        'ButtonPushedFcn',{@ui.msk.mskBuilderOpen,f},'Enable','on');
    uibutton(bDrawBt,'state','Text','Check ROI curve','Tag','checkROI',...
        'ValueChangedFcn',{@ui.mov.updtCursorFunMov,f,'check','roi'},'Enable','on');
%     uibutton(bDrawBt,'push','Text','Extract ROI','Tag','extract','ButtonPushedFcn',...
%         {@ui.mov.updtCursorFunMov,f,'extract','cell'},'Interruptible','off','BusyAction','cancel');
    
    % event detection top ----
    ui.com.addDetectTab(f,pDeOut);
    
    % filtering ----
    bFilter = uigridlayout(pFilter,'Padding',[0,5,0,0],'ColumnWidth',{5,'1x','1x',5},'RowHeight',{20,20,'1x',20},'RowSpacing',5);
    p = uilabel(bFilter,'Text','Proof reading','BackgroundColor',[0 0.3 0.6],'FontColor','white');
    p.Layout.Column = [1,4];
    p = uibutton(bFilter,'state','Text','view/favourite','Tag','viewFavClick',...
        'ValueChangedFcn',{@ui.mov.updtCursorFunMov,f,'addrm','viewFav'});
    p.Layout.Column = 2;
    p = uibutton(bFilter,'state','Text','delete/restore','Tag','delResClick',...
        'ValueChangedFcn',{@ui.mov.updtCursorFunMov,f,'addrm','delRes'});
    p.Layout.Column = 3;
    p = uitable(bFilter,'Data',zeros(5,4),'Tag','filterTable',...
        'CellEditCallback',{@ui.detect.filterUpdt,f},'RowName',[],...
        'ColumnWidth',{20 125 75 75},'ColumnName',{'','Feature','Min','Max'},...
        'FontSize',12,'ColumnEditable',[true,false,true,true]);
    p.Layout.Column = [1,4];p.Layout.Row = 3;
    p = uibutton(bFilter,'push','Text','addAllFiltered','Tag','addAllFiltered',...
        'ButtonPushedFcn',{@ui.mov.updtCursorFunMov,f,'addrm','addAll'});
    p.Layout.Column = 2;p.Layout.Row = 4;
    p = uibutton(bFilter,'push','Text','FeaturesPlot','Tag','featuresPlot',...
        'ButtonPushedFcn',{@ui.mov.featurePlot,f});
    p.Layout.Column = 3;

    % Select Button
    gSelect = uigridlayout(bFilter,'Tag','sliceSelect','Padding',[10,0,10,0],'ColumnWidth',{'1x'},'RowHeight',{'1x','1x','1x','1x','1x','1x',20},'RowSpacing',3);
    gSelect.Layout.Column = [1,4];gSelect.Layout.Row = 3;
    uilabel(gSelect,'Text','  X Location');
    uislider(gSelect,'Tag','xPos','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.mov.sliceMov3D,f});
    uilabel(gSelect,'Text','  Y Location');
    uislider(gSelect,'Tag','yPos','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.mov.sliceMov3D,f});
    uilabel(gSelect,'Text','  Z Location');
    uislider(gSelect,'Tag','zPos','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.mov.sliceMov3D,f});
    bSelectBt = uigridlayout(gSelect,'Padding',[80,0,80,0],'ColumnWidth',{'1x',},'RowHeight',{'1x'},'RowSpacing',5,'ColumnSpacing',5);
    uibutton(bSelectBt,'push','Text','Select','Tag','select3D','ButtonPushedFcn',{@ui.mov.select3D,f});
    gSelect.Visible = 'off';

    % exporting ----
    bExp = uigridlayout(pExport,'Padding',[0,5,0,0],'ColumnWidth',{5,'1x','1x',5},'RowHeight',{20,20,20,20},'RowSpacing',5);
    p = uilabel(bExp,'Text','Export','BackgroundColor',[0 0.3 0.6],'FontColor','white'); p.Layout.Column = [1,4];
    p = uicheckbox(bExp,'Text','AQuA project','Value',1,'Tag','expEvt');p.Layout.Column = 2;
    uicheckbox(bExp,'Text','Feature Table','Value',1,'Tag','expFt');
    p = uicheckbox(bExp,'Text','Movie with overlay','Value',1,'Tag','expMov');p.Layout.Column = 2; p.Layout.Row = 3;
    % uicheckbox(bExp,'Text','Events (Only position)','Value',0,'Tag','expEvt2');
    p = uibutton(bExp,'push','Text','Export / Save','ButtonPushedFcn',{@ui.proj.getOutputFolder,f});
    p.Layout.Column = [2,3]; p.Layout.Row = 4;
    
    % misc. tools ----
    bSys = uigridlayout(pSys,'Padding',[0,5,0,0],'ColumnWidth',{5,'1x','1x',5},'RowHeight',{20,20},'RowSpacing',5);
    p = uilabel(bSys,'Text','Others','BackgroundColor',[0 0.3 0.6],'FontColor','white');p.Layout.Column = [1,4];
    p = uibutton(bSys,'push','Text','Restart','ButtonPushedFcn',{@ui.proj.back2welcome,f});p.Layout.Column = 2;
    uibutton(bSys,'push','Text','Send to workspace','ButtonPushedFcn',{@ui.proj.exportVar2Base,f});
end



