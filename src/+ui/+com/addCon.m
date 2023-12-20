function addCon(f,dbg)

Pix_SS = get(0,'screensize');
h0 = Pix_SS(4)+22; w0 = Pix_SS(3);  % 50 is taskbar size
btSt = ui.proj.initStates();
setappdata(f,'btSt',btSt);
setappdata(f,'guiWelcomeSz',[w0/2-200,h0/2-150,400,300]);
setappdata(f,'guiMainSz',[w0/2-700 h0/2-400 1400 850]);

f.Position = getappdata(f,'guiWelcomeSz');
f.Resize = 'on';

% top level panels
g = uipanel(f,'Tag','g','Units','normalized','Position',[0,0,1,1],'BorderType','none');
bWel = uigridlayout(g,'Tag','Card1','ColumnWidth',{'1x'},'RowHeight',{'1x','1x'},'Padding',[100,75,100,75]);
bNew = uigridlayout(g,'Tag','Card2','ColumnWidth',{'1x'},'RowHeight',{90,120,40},'Padding',[5,5,5,5],'ColumnSpacing',5,'RowSpacing',5);
ui.com.addCon_proj(f,bWel,bNew);
bNew.Visible = 'off';
bWel.Visible = "off";

% main UI
% f.Position = getappdata(f,'guiMainSz');
bMain = uigridlayout(g,'Tag','Card3','ColumnWidth',{300,'1x',300},'RowHeight',{'1x'},'Padding',[5,5,5,5]);
pWkfl = uipanel(bMain,'BorderType','none');
pDat = uipanel(bMain);
pTool = uipanel(bMain,'BorderType','none');

ui.com.addCon_wkfl(f,pWkfl);
ims = ui.com.addCon_dat(f,pDat);
ui.com.addCon_tools(f,pTool);
bMain.Visible = 'off';

% mask builder UI
bMsk = uigridlayout(g,'Tag','Card4','ColumnWidth',{300,'1x',300},'RowHeight',{'1x'},'Padding',[5,5,5,5]);
pWkflMsk = uipanel(bMsk,'BorderType','none');
pDatMsk = uipanel(bMsk);
pToolMsk = uipanel(bMsk,'BorderType','none');

ui.msk.addCon_wkflMsk(f,pWkflMsk);
[imsMsk,movBuilder] = ui.msk.addCon_datMsk(f,pDatMsk);
ui.msk.addCon_toolsMsk(f,pToolMsk);
bMsk.Visible = "off";

% default GUI settings
bWel.Visible = 'on';
fh = guihandles(f);
fh.ims = ims;
fh.imsMsk = imsMsk;
fh.movBuilder = movBuilder;
guidata(f,fh);
col = fh.Pan.BackgroundColor;
setappdata(f,'col',col);

ui.proj.updtPreset([],[],f);

f.CloseRequestFcn = {@ui.proj.closeMe,f};

% debug UI
if dbg>0
    [ov,bd,scl,~] = ui.proj.prepInitUIStruct();
    setappdata(f,'ov',ov);
    setappdata(f,'bd',bd);
    setappdata(f,'scl',scl);
end
if dbg==1
    fh.Card1.Visible = 'off';
    fh.Card2.Visible = 'off';
    fh.Card3.Visible = 'on';
    fh.Card4.Visible = 'off';
    f.KeyReleaseFcn = {@ui.mov.findKeyPress};
    fh.overlayColor.Enable = 'on';
end
if dbg==2
    fh.Card1.Visible = 'off';
    fh.Card2.Visible = 'off';
    fh.Card3.Visible = 'off';
    fh.Card4.Visible = 'on';
end
if dbg>0
    f.Position = getappdata(f,'guiMainSz');
end

setappdata(f,'dbg',dbg);

end





