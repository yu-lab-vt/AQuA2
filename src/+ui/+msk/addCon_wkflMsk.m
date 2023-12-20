function addCon_wkflMsk(f, pWkflMsk)

    % workflow panels ----
    bWkfl = uigridlayout(pWkflMsk,'ColumnWidth',{'1x'},'RowHeight',{390,150},'Padding',[0,0,0,0],'RowSpacing',5);
    pMsk = uipanel(bWkfl);
    pSave = uipanel( bWkfl);

    % load masks ---
    bLoad = uigridlayout(pMsk,'ColumnWidth',{'1x'},'RowHeight',{100,'1x',20,20,20},'Padding',[0,5,0,0],'RowSpacing',5,'ColumnSpacing',5);
    gLoad = uigridlayout(bLoad,'ColumnWidth',{'1x',55,55,50,40},'RowHeight',{20,20,20,20},'Padding',[0,0,0,0],'RowSpacing',5,'ColumnSpacing',5);
    p = uilabel(gLoad,'Text','Load masks','BackgroundColor',[0 0.3 0.6],'FontColor','white');
    p.Layout.Column = [1,5];
    uilabel(gLoad, 'Text', ' Region');
    uibutton(gLoad, 'push','Text', 'SelfCH1', 'ButtonPushedFcn', {@ui.msk.readMsk, f, 'self_CH1', 'region'});
    uibutton(gLoad, 'push','Text', 'SelfCH2', 'ButtonPushedFcn', {@ui.msk.readMsk, f, 'self_CH2', 'region'});
    uibutton(gLoad, 'push','Text', 'Folder', 'ButtonPushedFcn', {@ui.msk.readMsk, f, 'folder', 'region'});
    uibutton(gLoad, 'push','Text', 'File', 'ButtonPushedFcn', {@ui.msk.readMsk, f, 'file', 'region'});
    uilabel(gLoad, 'Text', ' Region maker');
    uibutton(gLoad, 'push','Text', 'SelfCH1', 'ButtonPushedFcn', {@ui.msk.readMsk, f, 'self_CH1', 'regionMarker'});
    uibutton(gLoad, 'push','Text', 'SelfCH2', 'ButtonPushedFcn', {@ui.msk.readMsk, f, 'self_CH2', 'regionMarker'});
    uibutton(gLoad, 'push','Text', 'Folder', 'ButtonPushedFcn', {@ui.msk.readMsk, f, 'folder', 'regionMarker'});
    uibutton(gLoad, 'push','Text', 'File', 'ButtonPushedFcn', {@ui.msk.readMsk, f, 'file', 'regionMarker'});
    uilabel(gLoad, 'Text', ' Landmark');
    uibutton(gLoad, 'push','Text', 'SelfCH1', 'ButtonPushedFcn', {@ui.msk.readMsk, f, 'self_CH1', 'landmark'});
    uibutton(gLoad, 'push','Text', 'SelfCH2', 'ButtonPushedFcn', {@ui.msk.readMsk, f, 'self_CH2', 'landmark'});
    uibutton(gLoad, 'push','Text', 'Folder', 'ButtonPushedFcn', {@ui.msk.readMsk, f, 'folder', 'landmark'});
    uibutton(gLoad, 'push','Text', 'File', 'ButtonPushedFcn', {@ui.msk.readMsk, f, 'file', 'landmark'});

    % list of added masks
    t = uitable(bLoad, 'Data', zeros(0, 3), 'Tag', 'mskTable','RowName',[]);
    t.ColumnName = {'', 'Mask name', 'Type'};
    t.ColumnEditable = [false, false, false];
    t.ColumnWidth = {20,80,196};
    t.CellSelectionCallback = {@ui.msk.mskLstViewer, f, 'select'};

    uibutton(bLoad, 'push','Text', 'Remove', 'ButtonPushedFcn', {@ui.msk.mskLstViewer, f, 'remove'});
    uilabel(bLoad,'Text','');
    
    % Manually Select
    gSelect = uigridlayout(bLoad,'ColumnWidth',{'1x',60,60,60},'RowHeight',{'1x'},'Padding',[0,0,0,0],'RowSpacing',5,'ColumnSpacing',5);
    uilabel(gSelect, 'Text', ' Manually Select');
    uibutton(gSelect, 'push','Text', 'Clear', 'Tag','Clear', 'ButtonPushedFcn', {@ui.mov.updtCursorFunMov2,f,'clear'});
    uibutton(gSelect, 'push','Text', 'Add', 'Tag','AddBuilder', 'ButtonPushedFcn', {@ui.mov.updtCursorFunMov2,f,'add'});
    uibutton(gSelect, 'push','Text', 'Remove', 'Tag','RemoveBuilder', 'ButtonPushedFcn', {@ui.mov.updtCursorFunMov2,f,'rm'});
    
    % save masks and back to main UI ----
    bSave = uigridlayout(pSave,'ColumnWidth',{'1x'},'RowHeight',{20,75,20},'Padding',[0,5,0,0],'RowSpacing',5);
    uilabel(bSave,'Text','Save regions/landmarks','BackgroundColor',[0 0.3 0.6],'FontColor','white');
    gSave = uigridlayout(bSave,'ColumnWidth',{'1x',120},'RowHeight',{20,20,20},'Padding',[0,0,0,0],'RowSpacing',5,'ColumnSpacing',5);
    uilabel(gSave, 'Text', ' Role of region markers');
    uidropdown(gSave, 'Items', {'Segment region', 'Remove region'}, 'Tag', 'saveMarkerOp');
    uilabel(gSave, 'Text', ' Combine region masks');
    uidropdown(gSave, 'Items', {'OR', 'AND', 'SUB'}, 'Tag', 'saveMskRegOp');
    uilabel(gSave, 'Text', ' Combine landmark masks');
    uidropdown(gSave, 'Items', {'OR', 'AND', 'SUB'}, 'Tag', 'saveMskLmkOp');

    bSaveBtn = uigridlayout(bSave,'ColumnWidth',{'1x','1x'},'RowHeight',{'1x'},'Padding',[0,0,0,0],'RowSpacing',5,'ColumnSpacing',20);
    uibutton(bSaveBtn, 'Text', 'Apply & back', 'ButtonPushedFcn', {@ui.msk.saveMsk, f, 0});
    uibutton(bSaveBtn, 'Text', 'Discard & back', 'ButtonPushedFcn', {@ui.msk.saveMsk, f, 1});

end 
