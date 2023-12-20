function addCon_tools(f,pTool)
% tools panels
bTool = uigridlayout(pTool,'Padding',[0,0,0,0],'ColumnWidth',{'1x'},'RowHeight',{608,'1x'},'RowSpacing',5);
pLayer = uipanel('Parent',bTool);
pEvtMngr = uipanel('Parent',bTool,'Tag','pEvtMngr');

% layer manager
ui.com.addConLayer(f,pLayer);

%%
% event manager
bEvt = uigridlayout(pEvtMngr,'Padding',[0,3,0,0],'ColumnWidth',{'1x'},'RowHeight',{20,45,'1x',20},'RowSpacing',3,'ColumnSpacing',5);
uilabel(bEvt,'Text','Favourite','BackgroundColor',[0 0.3 0.6],'FontColor','white');
bEvtBtn = uigridlayout(bEvt,'Padding',[5,0,5,0],'ColumnWidth',{'1x','1x','1x'},'RowHeight',{'1x','1x'},'RowSpacing',3,'ColumnSpacing',5);
tb = uitable(bEvt,'Data',zeros(0,5),'Tag','evtTable');
bEvtAdd = uigridlayout(bEvt,'Padding',[5,0,5,0],'ColumnWidth',{50,40,40,50,40,40},'RowHeight',{'1x'},'RowSpacing',3,'ColumnSpacing',5);

uibutton(bEvtBtn,'push','Text','Select all','ButtonPushedFcn',{@ui.evt.evtMngrSelAll,f});
uibutton(bEvtBtn,'push','Text','Delete','ButtonPushedFcn',{@ui.evt.evtMngrDeleteSel,f});
uibutton(bEvtBtn,'push','Text','Details','ButtonPushedFcn',{@ui.evt.showDetails,f});
uibutton(bEvtBtn,'push','Text','Show curves','ButtonPushedFcn',{@ui.evt.evtMngrShowCurve,f});
uibutton(bEvtBtn,'push','Text','Save curves','ButtonPushedFcn',{@ui.evt.saveCurveFig,f});
uibutton(bEvtBtn,'push','Text','Save waves','ButtonPushedFcn',{@ui.evt.saveWaves,f});

tb.ColumnName = {'','CH','Index','Frame','Size','Dur','df/f','Tau'};
tb.ColumnWidth = {20 40 56 63 48 45 48 48};
tb.ColumnSortable = true;
tb.RowName = [];
tb.ColumnEditable = [true,false,false,false,false,false];
tb.CellSelectionCallback = {@ui.evt.evtMngrSelectOne,f};
tb.FontSize = 12;

uilabel(bEvtAdd,'Text','Ch1 ID');
uieditfield(bEvtAdd,'Tag','toolsAddEvt1');
uibutton(bEvtAdd,'push','Text','Add','ButtonPushedFcn',{@ui.evt.addOne,f});
uilabel(bEvtAdd,'Text','Ch2 ID');
uieditfield(bEvtAdd,'Tag','toolsAddEvt2');
uibutton(bEvtAdd,'push','Text','Add','ButtonPushedFcn',{@ui.evt.addOne2,f});
end








