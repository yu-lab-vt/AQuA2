function ims = addCon_dat(f,pDat)

% top level panels
bDat = uigridlayout(pDat,'Padding',[0,5,0,5],'ColumnWidth',{'1x'},'RowHeight',{20,'1x',20,200},'ColumnSpacing',0,'RowSpacing',5);

% controls --------------
% image tools
pImgTool = uigridlayout(bDat,'Padding',[10,0,10,0],'ColumnWidth',{80,120,60,50,80,50,80,80,'1x'},'RowHeight',{'1x'},'ColumnSpacing',5,'RowSpacing',0);
uibutton(pImgTool,'state','Text','Pan','Tag','Pan','ValueChangedFcn',{@ui.mov.movPan,f});
uibutton(pImgTool,'state','Text','Zoom','Tag','Zoom','ValueChangedFcn',{@ui.mov.movZoom,f});
uilabel(pImgTool,'Text','Jump to');
uieditfield(pImgTool,'Value','1','ValueChangedFcn',{@ui.mov.jumpTo,f},'Tag','jumpTo');
uilabel(pImgTool,'Text','Play speed');
uieditfield(pImgTool,'Value','15','Tag','playbackRate');
uibutton(pImgTool,'state','Text','Side by side','Tag','sbs','ValueChangedFcn',{@ui.mov.movSideBySide,f});
uibutton(pImgTool,'state','Text','GaussFilter','Tag','GaussFilter','ValueChangedFcn',{@ui.mov.movGauss,f},'Enable','off');
uilabel(pImgTool,'Text','1/1','HorizontalAlignment','right','Tag','curTime'); 

% movie views ---------------
% single movie view
pMovTop = uipanel(bDat,'Tag','movTop','BorderType','none');
bMov1Top = uigridlayout(pMovTop,'Tag','bMov1Top','Padding',[5,5,5,5],'ColumnWidth',{'1x'},'RowHeight',{'1x',50},'ColumnSpacing',0,'RowSpacing',5);
pMov1 = uiaxes(bMov1Top,'ActivePositionProperty','Position','Tag','mov');

% bMov1Top.Heights = [-1,50];

pMov1.XTick = [];
pMov1.YTick = [];
d0 = zeros(100,100,3);
pMov1.XLim = [1 100];
pMov1.YLim = [1 100];
pMov1.DataAspectRatio = [1 1 1];
im1 = image(pMov1,'CData',flipud(d0));
im1.CDataMapping = 'scaled';
% im1.ButtonDownFcn = {@ui.mov.movClick,f,'sel','evt'};  % show clicked event

pMov1ColMap = uigridlayout(bMov1Top,'Tag','pMovColMap','Padding',[0,0,0,0],'ColumnWidth',{'1x'},'RowHeight',{'1x'},'ColumnSpacing',10,'RowSpacing',5);
pCol1 = uiaxes(pMov1ColMap,'ActivePositionProperty','Position','Tag','movColMap');
% pCol1 = axes('Parent',pMov1ColMap,'ActivePositionProperty','Position','Tag','movColMap');
c0 = repmat(1:100,1,3,3); pCol1.XLim = [1 100]; %pCol1.YLim = [1 1];
pCol1.YTick = [];
im1Col = image(pCol1,'CData',c0);
pCol1.DataAspectRatio = [1 1 1];
pMov1ColMap.Visible = 'off';

bMov1Top.Visible = 'off';

% side by side view
% tabSide = uitab(pMovTop,'Title','-----------Side By Side View-----------');
% tabSide = uipanel('Parent',pMovTop,'Tag','bMovSide');
bMov2Top = uigridlayout(pMovTop,'Tag','bMov2Top','Padding',[5,5,5,5],'ColumnWidth',{'1x','1x'},'RowHeight',{25,'1x',50},'ColumnSpacing',10,'RowSpacing',5);
% view control
str00 = {'Raw','Raw + overlay','Maximum Projection','Average Projection','dF / sigma','Threshold preview','Rising map (20%)','Rising map (50%)','Rising map (80%)'};
uidropdown(bMov2Top,'Items',str00,'Tag','movLType','ValueChangedFcn',{@ui.mov.movViewSel,f},'Value','Raw + overlay');
uidropdown(bMov2Top,'Items',str00,'Tag','movRType','ValueChangedFcn',{@ui.mov.movViewSel,f},'Value','Raw');

pMov2a = uiaxes('Parent',bMov2Top,'ActivePositionProperty','Position','Tag','movL');
pMov2a.XTick = [];
pMov2a.YTick = [];
d0 = zeros(100,100);
pMov2a.XLim = [1 100];
pMov2a.YLim = [1 100];
im2a = image(pMov2a,'CData',flipud(d0));
im2a.CDataMapping = 'scaled';
% im2a.ButtonDownFcn = {@ui.mov.movClick,f,'sel','evt'};  % show clicked event
pMov2a.DataAspectRatio = [1 1 1];

pMov2b = uiaxes('Parent',bMov2Top,'ActivePositionProperty','Position','Tag','movR');
pMov2b.XTick = [];
pMov2b.YTick = [];
d0 = zeros(100,100);
pMov2b.XLim = [1 100];
pMov2b.YLim = [1 100];
im2b = image(pMov2b,'CData',flipud(d0));
im2b.CDataMapping = 'scaled';
% im2b.ButtonDownFcn = {@ui.mov.movClick,f,'sel','evt'};  % show clicked event
pMov2b.DataAspectRatio = [1 1 1];

pMov2ColMap = uigridlayout(bMov2Top,'Tag','pMov2ColMap','Padding',[0,0,0,0],'ColumnWidth',{'1x','1x'},'RowHeight',{'1x'},'ColumnSpacing',10,'RowSpacing',5);
pMov2ColMap.Layout.Column = [1,2];
pCol2a = uiaxes('Parent',pMov2ColMap,'Tag','movLColMap');
c0 = 1:100; pCol2a.XLim = [1 100];
pCol2a.YTick = [];
im2aCol = image(pCol2a,'CData',c0);
pCol2a.DataAspectRatio = [1 1 1];

pCol2b = uiaxes('Parent',pMov2ColMap,'Tag','movRColMap');
c0 = 1:100; pCol2b.XLim = [1 100];
pCol2b.YTick = [];
im2bCol = image(pCol2b,'CData',c0);
pCol2b.DataAspectRatio = [1 1 1];
% pMov2ColMap.Visible = 'off';
bMov2Top.Visible = 'off';
bMov1Top.Visible = 'on';


% image play
pImgCon = uigridlayout(bDat,'Padding',[10,0,10,0],'ColumnWidth',{50,50,20,'1x',20,60,60},'RowHeight',{'1x'},'ColumnSpacing',5,'RowSpacing',0);
uibutton(pImgCon,'push','Text','Play','ButtonPushedFcn',{@ui.mov.playMov,f},'Tag','play');
uibutton(pImgCon,'push','Text','Pause','ButtonPushedFcn',{@ui.mov.pauseMov,f});
uibutton(pImgCon,'push','Text','<','ButtonPushedFcn',{@ui.mov.stepOne,f,-1});
uislider(pImgCon,'Tag','sldMov','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.mov.stepOne,f});
uibutton(pImgCon,'push','Text','>','ButtonPushedFcn',{@ui.mov.stepOne,f,1});
uilabel(pImgCon,'Text','nEvt','Tag','nEvtName','HorizontalAlignment','center');
uilabel(pImgCon,'Text','0','Tag','nEvt','BackgroundColor',[1,1,1],'HorizontalAlignment','center');

% curves
pCurve = uiaxes('Parent',bDat,'ActivePositionProperty','Position','Tag','curve');
pCurve.XTick = [];
pCurve.YTick = [];
pCurve.YLim = [-0.1,0.1];

% images
ims = [];
ims.im1 = im1;
ims.im2a = im2a;
ims.im2b = im2b;
ims.im1Col = im1Col;
ims.im2aCol = im2aCol;
ims.im2bCol = im2bCol;
z = zoom(f);z.ActionPostCallback = {@ui.mov.mypostcallback,f};
z = pan(f);z.ActionPostCallback = {@ui.mov.mypostcallback,f};
pMov1.Toolbar.Visible = 'off';
pMov2a.Toolbar.Visible = 'off';
pMov2b.Toolbar.Visible = 'off';
pCol1.Toolbar.Visible = 'off';
pCol2a.Toolbar.Visible = 'off';
pCol2b.Toolbar.Visible = 'off';
pCurve.Toolbar.Visible = 'off';
end