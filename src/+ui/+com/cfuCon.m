function cfuCon(fCFU,fOut)
% top level panels
Pix_SS = get(0,'screensize');
h0 = Pix_SS(4)+22; w0 = Pix_SS(3);  % 50 is taskbar size
btSt = ui.proj.initStates();
setappdata(fCFU,'btSt',btSt);
setappdata(fCFU,'guiMainSz',[w0/2-700 h0/2-400 1400 850]);
fCFU.Position = getappdata(fCFU,'guiMainSz');

bMain = uigridlayout(fCFU,'ColumnWidth',{300,'1x',300},'RowHeight',{'1x'},'Padding',[5,5,5,5]);
opts = getappdata(fOut,'opts');

% main UI
pWkfl = uipanel(bMain,'BorderType','none');
pDat = uipanel(bMain);
pTool = uipanel(bMain,'BorderType','none');

%% %% left panel
bWkfl = uigridlayout(pWkfl,'ColumnWidth',{'1x'},'RowHeight',{200,180,110,80,175},'Padding',[0,0,0,0],'RowSpacing',10);
pDetect = uipanel('Parent',bWkfl,'Tag','pDetect');
pOperation = uipanel('Parent',bWkfl,'Tag','pOperation');
pGroup = uipanel('Parent',bWkfl,'Tag','pGroup');
pSys = uipanel('Parent',bWkfl,'Tag','pSys');
pSelect = uipanel('Parent',bWkfl,'Tag','pSelect');

%% detection
bDeOut = uigridlayout(pDetect,'ColumnWidth',{'1x'},'RowHeight',{20,55,55,20,20},'Padding',[0,15,0,0],'RowSpacing',5);
uilabel(bDeOut,'Text','CFU detections','BackgroundColor',[0 0.3 0.6],'FontColor','white');
deOutTab = uigridlayout(bDeOut,'Tag','deOutTab','RowSpacing',5,'ColumnSpacing',5,'ColumnWidth',{50,'1x'},'RowHeight',{20,20},'Padding',[10,0,10,10]);
uieditfield(deOutTab,'Value','0.5','Tag','alpha');
uilabel(deOutTab,'Text','Overlap threshold (CH1)');
uieditfield(deOutTab,'Value','3','Tag','minNumEvt');
uilabel(deOutTab,'Text','Minimum number of event in CFU (CH1)');


deOutTab2 = uigridlayout(bDeOut,'Tag','deOutTab2','RowSpacing',5,'ColumnSpacing',5,'ColumnWidth',{50,'1x'},'RowHeight',{20,20},'Padding',[10,0,10,10]);
uieditfield(deOutTab2,'Value','0.5','Tag','alpha2');
uilabel(deOutTab2,'Text','Overlap threshold (CH2)');
uieditfield(deOutTab2,'Value','3','Tag','minNumEvt2');
uilabel(deOutTab2,'Text','Minimum number of event in CFU (CH2)');

if opts.singleChannel
    deOutTab2.Visible = 'off';
end

p = uicheckbox(bDeOut,'Text','Use spatial weighted map (yes)| spatial footprint (no)','Value',1,'Tag','spatialOption');

deOutCon = uigridlayout(bDeOut,'RowSpacing',5,'ColumnSpacing',5,'ColumnWidth',{'1x'},'RowHeight',{20},'Padding',[100,0,100,0]);
uibutton(deOutCon,'push','Text','Run','Tag','deOutRun','ButtonPushedFcn',{@ui.detect.CFURunGui,fCFU,fOut});

%% Operations
bOp = uigridlayout(pOperation,'ColumnWidth',{'1x'},'RowHeight',{20,45,20,75},'Padding',[0,15,0,0],'RowSpacing',5);
uilabel(bOp,'Text','Operations','BackgroundColor',[0 0.3 0.6],'FontColor','white');

bOp00 = uigridlayout(bOp,'ColumnWidth',{100,'1x'},'RowHeight',{20,20},'Padding',[10,0,0,0],'RowSpacing',5);
uibutton(bOp00,'state','Text','view/favorite','Tag','viewButton','Enable','off','ValueChangedFcn',{@cfu.pickCFU,fCFU,fOut,'view'});
uilabel(bOp00,'Text','Add CFU to favorite table');
uibutton(bOp00,'push','Text','add all','Tag','addAllButton','Enable','off','ButtonPushedFcn',{@cfu.allAllFav,fCFU});
uilabel(bOp00,'Text','Add all CFUs to favorite table');
uilabel(bOp,'Text','----- Window Size for calculting dependency -----','HorizontalAlignment','center');
bOp0 = uigridlayout(bOp,'ColumnWidth',{100,'1x'},'RowHeight',{20,20,20},'Padding',[10,0,0,0],'RowSpacing',5);
uieditfield(bOp0,'Tag','winSz','Value','0');
uislider(bOp0,'Tag','sldWinSz','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@winSlider,fCFU,fOut});
uibutton(bOp0,'state','Text','Pick CFUs','Tag','pickButton','Enable','off','ValueChangedFcn',{@cfu.pickCFU,fCFU,fOut,'pick'});
uilabel(bOp0,'Text','Pick CFUs (only keep 2 in canvas)');
uibutton(bOp0,'push','Text','All dependencies','Tag','calDep','Enable','off','ButtonPushedFcn',{@cfu.calAllDependency,fCFU,fOut});
uilabel(bOp0,'Text','All dependencies');

%%
bGroup = uigridlayout(pGroup,'ColumnWidth',{'1x'},'RowHeight',{20,50,25},'Padding',[0,15,0,0],'RowSpacing',5);
uilabel(bGroup,'Text','Group','BackgroundColor',[0 0.3 0.6],'FontColor','white');
dGroup = uigridlayout(bGroup,'Tag','dGroup','ColumnWidth',{50,'1x'},'RowHeight',{20,20},'Padding',[10,0,0,0],'RowSpacing',5);
uieditfield(dGroup,'Value','1e-5','Tag','pThr','Enable','off');
uilabel(dGroup,'Text','p-Value significance of dependency threshold');
uieditfield(dGroup,'Value','3','Tag','minNumCFU','Enable','off');
uilabel(dGroup,'Text','Minimum number of CFUs in each group');
dGrupButton = uigridlayout(bGroup,'RowSpacing',5,'ColumnSpacing',5,'ColumnWidth',{'1x'},'RowHeight',{20},'Padding',[100,0,100,0]);
uibutton(dGrupButton,'push','Text','Run','Tag','buttonGroup','Enable','off','ButtonPushedFcn',{@cfu.groupCFU,fCFU,fOut});

%% Out
bSys = uigridlayout(pSys,'ColumnWidth',{'1x'},'RowHeight',{20,'1x'},'Padding',[0,15,0,0],'RowSpacing',20);
uilabel(bSys,'Text','Others','BackgroundColor',[0 0.3 0.6],'FontColor','white');
bSys0 = uigridlayout(bSys,'ColumnWidth',{70,70,120},'RowHeight',{20},'Padding',[10,0,10,0],'RowSpacing',5);
uibutton(bSys0,'Text','Return','ButtonPushedFcn',{@cfu.returnMajorGUI,fCFU,fOut});
uibutton(bSys0,'Text','Output','ButtonPushedFcn',{@cfu.output,fCFU,fOut});
uibutton(bSys0,'Text','Send to workspace','ButtonPushedFcn',{@cfu.workSpace,fCFU,fOut});

%% Select
bSelect = uigridlayout(pSelect,'ColumnWidth',{'1x'},'RowHeight',{20,15,15,15,15,15,15,20,'1x'},'Padding',[0,15,0,0],'RowSpacing',5);
uilabel(bSelect,'Text','Select','BackgroundColor',[0 0.3 0.6],'FontColor','white');
uilabel(bSelect,'Text','  X Location');
uislider(bSelect,'Tag','xPos','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@cfu.sliceMov3D,fCFU});
uilabel(bSelect,'Text','  Y Location');
uislider(bSelect,'Tag','yPos','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@cfu.sliceMov3D,fCFU});
uilabel(bSelect,'Text','  Z Location');
uislider(bSelect,'Tag','zPos','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@cfu.sliceMov3D,fCFU});
bSelectBt = uigridlayout(bSelect,'Padding',[10,0,10,0],'ColumnWidth',{'1x','1x','1x'},'RowHeight',{'1x'},'RowSpacing',5,'ColumnSpacing',5);
uibutton(bSelectBt,'push','Text','Slice view','Tag','sliceview','ButtonPushedFcn',{@cfu.sliceView,fCFU});
uibutton(bSelectBt,'push','Text','3D view','Tag','3Dview','ButtonPushedFcn',{@cfu.view3D,fCFU});
uibutton(bSelectBt,'push','Text','Select','Tag','select3D','ButtonPushedFcn',{@cfu.select3D,fCFU,fOut});
pSelect.Visible = 'off';

%% %% Data Panel
% top level panels
bDat = uigridlayout(pDat,'ColumnWidth',{'1x'},'RowHeight',{'1x',200},'Padding',[0,0,0,0],'RowSpacing',5);

% default GUI settings
fhOut = guidata(fOut);
datM = fhOut.averPro1;
[H,W,L] = size(datM);
datM = datM - min(datM(:));
datM = datM/max(datM(:));

% movie views ---------------
% single movie view
if opts.sz(3) == 1
    % 2D
    datM = cat(3,datM,datM,datM);
    if(opts.singleChannel)
        pMovTop1 = uigridlayout(bDat,'ColumnWidth',{'1x'},'RowHeight',{'1x'},'Padding',[0,0,0,0],'RowSpacing',5);
        pMov1 = uiaxes('Parent',pMovTop1,'ActivePositionProperty','Position','Tag','mov');
        pMov1.XTick = [];
        pMov1.YTick = [];
        pMov1.XLim = [1 W];
        pMov1.YLim = [1,H];
        im1 = image(pMov1,'CData',flipud(datM));
        im1.CDataMapping = 'scaled';
        pMov1.DataAspectRatio = [1 1 1];
    
        % images
        ims = [];
        ims.im1 = im1;
    else
        pMovTop2 = uigridlayout(bDat,'ColumnWidth',{'1x','1x'},'RowHeight',{'1x'},'Padding',[0,0,0,0],'RowSpacing',5);
        pMov2a = uiaxes('Parent',pMovTop2,'ActivePositionProperty','Position','Tag','movL');
        pMov2a.XTick = [];
        pMov2a.YTick = [];
        pMov2a.XLim = [1 W];
        pMov2a.YLim = [1 H];
        im2a = image(pMov2a,'CData',flipud(datM));
        im2a.CDataMapping = 'scaled';
        pMov2a.DataAspectRatio = [1 1 1];
        
        datM = fhOut.averPro2;
        datM = datM - min(datM(:));
        datM = datM/max(datM(:));
        datM = cat(3,datM,datM,datM);    
        
        pMov2b = uiaxes('Parent',pMovTop2,'ActivePositionProperty','Position','Tag','movR');
        pMov2b.XTick = [];
        pMov2b.YTick = [];
        pMov2b.XLim = [1 W];
        pMov2b.YLim = [1 H];
        im2b = image(pMov2b,'CData',flipud(datM));
        im2b.CDataMapping = 'scaled';
        pMov2b.DataAspectRatio = [1 1 1];
    
        % images
        ims = [];
        ims.im2a = im2a;
        ims.im2b = im2b;
    end
else
    % 3D
    bd = getappdata(fOut,'bd');
    if bd.isKey('cell')
        mask = bd('cell');
    else
        mask = true(opts.sz(1:3));
    end

    btSt = getappdata(fOut,'btSt');
    bkColors = [0,0,0;
        0,0,0;
        0 0.3290 0.5290;
        .5,.5,.5;
        1,1,1];
    gdColors = [0,0,0;
        .3,.3,.3;
        0 0.5610 1;
        .8,.8,.8;
        1,1,1];

    if(opts.singleChannel)
        pMovTop1 = uigridlayout(bDat,'ColumnWidth',{'1x'},'RowHeight',{'1x'},'Padding',[0,0,0,0],'RowSpacing',5);
        pMov1 = viewer3d(pMovTop1,'Tag','mov');
        pMov1.Layout.Row = 1;
        pMov1.BackgroundColor = bkColors(btSt.bkCol,:);
        pMov1.BackgroundGradient = "on";
        pMov1.GradientColor = gdColors(btSt.bkCol,:);
        pMov1.ScaleBar = 'on';
        pMov1.Interactions = {'zoom','rotate','pan','axes','slice'};
        pMov1.Lighting = 'off';
    else
        pMovTop2 = uigridlayout(bDat,'ColumnWidth',{'1x','1x'},'RowHeight',{'1x'},'Padding',[0,0,0,0],'RowSpacing',5);
        pMov2a = viewer3d(pMovTop2,'Tag','movL');
        pMov2a.BackgroundColor = bkColors(btSt.bkCol,:);
        pMov2a.BackgroundGradient = "on";
        pMov2a.GradientColor = gdColors(btSt.bkCol,:);
        pMov2a.ScaleBar = 'on';
        pMov2a.Interactions = {'zoom','rotate','pan','axes','slice'};
        pMov2a.Lighting = 'off';
        
        pMov2b = viewer3d(pMovTop2,'Tag','movR');
        pMov2b.BackgroundColor = bkColors(btSt.bkCol,:);
        pMov2b.BackgroundGradient = "on";
        pMov2b.GradientColor = gdColors(btSt.bkCol,:);
        pMov2b.ScaleBar = 'on';
        pMov2b.Interactions = {'zoom','rotate','pan','axes','slice'};
        pMov2b.Lighting = 'off';
        addlistener(pMov2a,'CameraMoved',@cfu.updateCamera);
        addlistener(pMov2b,'CameraMoved',@cfu.updateCamera);
    end
end
% curves
pCurve = uiaxes('Parent',bDat,'ActivePositionProperty','Position','Tag','curve');
pCurve.XLim = [0,opts.sz(4)+1];
xticks(pCurve,'auto');
pCurve.YTick = [];
pCurve.YLim = [-0.1,0.1];

%% %% Right panel
pTool = uigridlayout(pTool,'ColumnWidth',{'1x'},'RowHeight',{325,300,200},'Padding',[0,0,0,0],'RowSpacing',5);
pTool0 = uipanel(pTool);
pTool1 = uipanel(pTool,'Tag','pTool1');
pTool2 = uipanel(pTool,'Tag','pTool2');

bTool0 = uigridlayout(pTool0,'ColumnWidth',{'1x'},'RowHeight',{20,20,20,20,20,20,20,20,20,20,20,20,20},'Padding',[0,0,0,0],'RowSpacing',5);
uilabel(bTool0,'Text','Adjustment','BackgroundColor',[0 0.3 0.6],'FontColor','white');
uilabel(bTool0,'Text','--- Background brightness/contrast ---','HorizontalAlignment','center');
uislider(bTool0,'Tag','sldBk','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.updtCFUint,fCFU,false});
uilabel(bTool0,'Text','--- Color brightness/contrast ---','HorizontalAlignment','center');
uislider(bTool0,'Tag','sldCol','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.updtCFUint,fCFU,false});
uilabel(bTool0,'Text','  Intensity Transparency (for 3D)','Tag','txtIntTrans','Enable','off');
uislider(bTool0,'Tag','sldIntensityTrans','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.updtCFUint,fCFU,false},'Enable','off');
uilabel(bTool0,'Text','  Overlay Transparency (for 3D)','Tag','txtOvTrans','Enable','off');
uislider(bTool0,'Tag','sldOverlayTrans','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.updtCFUint,fCFU,false},'Enable','off');
uilabel(bTool0,'Text','  Downsample XY dimension (for 3D)','Tag','txtDsXY','Enable','off');
uislider(bTool0,'Tag','sldDsXY','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@cfu.adjDS,fCFU},'Enable','off','Limits',[1,10],'Value',1);


bEvtBtn0 = uigridlayout(bTool0,'ColumnWidth',{'1x'},'RowHeight',{20},'Padding',[10,0,10,0],'ColumnSpacing',10);
uibutton(bEvtBtn0,'push','Text','switchBackground (for 3D)','Tag','switchBackground','ButtonPushedFcn',{@cfu.changeBackGroundColor,fCFU,fOut},'Enable','off');

bEvtBtn = uigridlayout(bTool0,'ColumnWidth',{'1x','1x'},'RowHeight',{20},'Padding',[10,0,10,0],'ColumnSpacing',10);
uibutton(bEvtBtn,'push','Text','Reassign Color','ButtonPushedFcn',{@ui.updtCFUint,fCFU,true});
uibutton(bEvtBtn,'push','Text','Show relative delay','Tag','delayButton','Enable','off','ButtonPushedFcn',{@cfu.delayMode,fCFU,fOut});


% event manager
bEvt = uigridlayout(pTool1,'Padding',[0,3,0,0],'ColumnWidth',{'1x'},'RowHeight',{20,45,'1x',20},'RowSpacing',3,'ColumnSpacing',5);
uilabel(bEvt,'Text','Favourite','BackgroundColor',[0 0.3 0.6],'FontColor','white');
bEvtBtn = uigridlayout(bEvt,'Padding',[5,0,5,0],'ColumnWidth',{'1x','1x','1x'},'RowHeight',{'1x','1x'},'RowSpacing',3,'ColumnSpacing',5);
tb = uitable(bEvt,'Data',zeros(0,5),'Tag','evtTable');
bEvtAdd = uigridlayout(bEvt,'Padding',[5,0,5,0],'ColumnWidth',{50,40,40,50,40,40},'RowHeight',{'1x'},'RowSpacing',3,'ColumnSpacing',5);

uibutton(bEvtBtn,'push','Text','Select all','ButtonPushedFcn',{@ui.evt.evtMngrSelAll,fCFU});
uibutton(bEvtBtn,'push','Text','Delete','ButtonPushedFcn',{@cfu.deleteCFU,fCFU});
uibutton(bEvtBtn,'push','Text','Show curves','ButtonPushedFcn',{@cfu.showSelectCurves,fCFU});
uibutton(bEvtBtn,'push','Text','Save curves','ButtonPushedFcn',{@ui.evt.saveCurveFig,fCFU});
uibutton(bEvtBtn,'push','Text','Save waves','ButtonPushedFcn',{@cfu.saveWaves,fCFU,fOut});

tb.ColumnName = {'','CH','Id','# Evt','Event List'};
tb.ColumnWidth = {20 40 40 55 135};
tb.ColumnSortable = true;
tb.RowName = [];
tb.ColumnEditable = [true,false,false,false,false,false];
tb.CellSelectionCallback = {@cfu.favCFUSelect,fCFU};
tb.FontSize = 12;

uilabel(bEvtAdd,'Text','Ch1 ID');
uieditfield(bEvtAdd,'Tag','toolsAddEvt1');
uibutton(bEvtAdd,'push','Text','Add','ButtonPushedFcn',{@cfu.addCFU,fCFU,1});
uilabel(bEvtAdd,'Text','Ch2 ID');
uieditfield(bEvtAdd,'Tag','toolsAddEvt2');
uibutton(bEvtAdd,'push','Text','Add','ButtonPushedFcn',{@cfu.addCFU,fCFU,2});

% group manager
bTool2 = uigridlayout(pTool2,'ColumnWidth',{'1x'},'RowHeight',{20,'1x'},'Padding',[0,0,0,0],'RowSpacing',5);
uilabel(bTool2,'Text','Group Table','BackgroundColor',[0 0.3 0.6],'FontColor','white');
tb = uitable(bTool2,'Data',zeros(0,4),'Tag','groupTable','RowName',[]);
tb.ColumnName = {'','Group Index','CFU number in Group','CFU indexes in it'};
tb.ColumnWidth = {20,92,92,92};
tb.ColumnEditable = [false,false,false,false];
tb.CellSelectionCallback = {@cfu.selectGroup,fCFU,fOut};
pTool1.Visible = 'off';
pTool2.Visible = 'off';

%%
fh = guihandles(fCFU);
if opts.sz(3)>1
    fh.txtIntTrans.Enable = 'on';
    fh.sldIntensityTrans.Enable = 'on';
    fh.sldIntensityTrans.Limits = [0,1];
    fh.sldIntensityTrans.Value = 0.5;
    fh.txtOvTrans.Enable = 'on';
    fh.sldOverlayTrans.Enable = 'on';
    fh.sldOverlayTrans.Limits = [0,1];
    fh.sldOverlayTrans.Value = 0.5;
    fh.txtDsXY.Enable = 'on';
    fh.sldDsXY.Enable = 'on';
    fh.switchBackground.Enable = 'on';
    fh.msk = mask;
    if opts.singleChannel
        im1 = volshow(datM,'Parent',pMov1,'Tag','im1');
        im1.RenderingStyle = "GradientOpacity";
        im1.AlphaData = zeros(size(datM),'single');
        im1.AlphaData(mask) = 0.5;
    
        % images
        ims = [];
        ims.im1 = im1;
    else
        im2a = volshow(datM,'Parent',pMov2a);
        im2a.RenderingStyle = "GradientOpacity";
        im2a.AlphaData = zeros(size(datM),'single');
        im2a.AlphaData(mask) = 0.5;
        
        datM = fhOut.averPro2;
        datM = datM - min(datM(:));
        datM = datM/max(datM(:));

        im2b = volshow(datM,'Parent',pMov2b);
        im2b.RenderingStyle = "GradientOpacity";
        im2b.AlphaData = zeros(size(datM),'single');
        im2b.AlphaData(mask) = 0.5;
    
        % images
        ims = [];
        ims.im2a = im2a;
        ims.im2b = im2b;
    end
end


fh.ims = ims;
fh.averPro1 = fhOut.averPro1;
fh.averPro2 = fhOut.averPro2;
fh.pickState = false;
fh.selectCFUs = [];
fh.groupShow = 0;
fh.delayMode = false;
fh.bkCol = btSt.bkCol;

fh.sldBk.Limits = [0,10];
fh.sldBk.Value = 1;

fh.sldCol.Limits = [0,2];
fh.sldCol.Value = 1;

fh.sldWinSz.Limits = [0,100];
fh.sldWinSz.Value = 0;

fh.xPos.Limits = [1,W];
fh.xPos.Value = (1+W)/2;
fh.yPos.Limits = [1,H];
fh.yPos.Value = (1+H)/2;
fh.favCFUs = [];
if L>1
    fh.zPos.Limits = [1,L];
    fh.zPos.Value = (1+L)/2;
end
fh.opts = opts;

guidata(fCFU,fh);
col = [0.3,0.3,0.7];
setappdata(fCFU,'col',col);

%%
fCFU.CloseRequestFcn = {@cfu.closeMe,fCFU};

%% load
needLoad = ~getappdata(fOut,'needReCheckCFU');
if(isempty(needLoad))
    needLoad = false;
end
if(needLoad && ~isempty(getappdata(fOut,'cfuInfo1')))
    setappdata(fCFU,'cfuInfo1',getappdata(fOut,'cfuInfo1'));
    setappdata(fCFU,'cfuInfo2',getappdata(fOut,'cfuInfo2'));
    setappdata(fCFU,'cols1',getappdata(fOut,'cols1'));
    setappdata(fCFU,'colorMap1',getappdata(fOut,'colorMap1'));
    setappdata(fCFU,'cols2',getappdata(fOut,'cols2'));
    setappdata(fCFU,'colorMap2',getappdata(fOut,'colorMap2'));
    ui.updtCFUint([],[],fCFU,false);
    fh.pickButton.Enable = 'on';
    fh.calDep.Enable = 'on';
end

if(needLoad && ~isempty(getappdata(fOut,'relation')))
    setappdata(fCFU,'relation',getappdata(fOut,'relation'));
    fh.pThr.Enable = 'on';
    fh.minNumCFU.Enable = 'on';
    fh.buttonGroup.Enable = 'on';
end

if(needLoad && ~isempty(getappdata(fOut,'groupInfo')))
    setappdata(fCFU,'groupInfo',getappdata(fOut,'groupInfo'));
    cfu.updtGrpTable(fCFU,fOut);
end

end

function winSlider(~,~,fCFU,f)
    fh = guidata(fCFU);
    fh.winSz.Value = num2str(round(fh.sldWinSz.Value));
    ui.updtCFUcurve([],[],fCFU,f);
end



