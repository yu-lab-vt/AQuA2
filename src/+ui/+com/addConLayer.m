function addConLayer(f,pLayer)

bLayer = uigridlayout(pLayer,'Padding',[0,0,0,0],'ColumnWidth',{'1x'},'RowHeight',{20,20,20,20,20,20,89,20,20,20,20,20,20,43,20,20,20,20,20,20,20,25,'1x'},'RowSpacing',3);
uilabel(bLayer,'Text','Layers','BackgroundColor',[0 0.3 0.6],'FontColor','white');
% movie
uilabel(bLayer,'Text','--- Movie brightness/contrast ---','HorizontalAlignment','center');
uilabel(bLayer,'Text','  Min');
uislider(bLayer,'Tag','sldMin','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.over.adjMov,f});
uilabel(bLayer,'Text','  Max');
uislider(bLayer,'Tag','sldMax','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.over.adjMov,f});

% single view
bLayer0 = uipanel(bLayer,'BorderType','none');
pBrightness = uigridlayout(bLayer0,'Tag','pBrightness','Padding',[0,0,0,0],'ColumnWidth',{'1x','1x'},'RowHeight',{'1x','1x'},'RowSpacing',3,'ColumnSpacing',5);
uilabel(pBrightness,'Text','  Brightness_Green (Ch1)','Tag','TextBri1'); uilabel(pBrightness,'Text','  Brightness_Red (Ch2)','Tag','TextBri2');
uislider(pBrightness,'Tag','sldBri1','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.over.adjMov,f});
uislider(pBrightness,'Tag','sldBri2','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.over.adjMov,f});
p = uilabel(pBrightness,'Text','  Intensity Transparency (for 3D)','Tag','txtIntTrans','Enable','off');
p.Layout.Column = [1,2];
p = uislider(pBrightness,'Tag','sldIntensityTrans','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.over.adjTrans3D,f,'Main'},'Enable','off');
p.Layout.Column = [1,2];
pBrightness.Visible = 'off';

% side by side view
pBS = uigridlayout(bLayer0,'Tag','pBrightnessSideBySide','Padding',[0,0,0,0],'ColumnWidth',{'1x','1x'},'RowHeight',{'1x','1x','1x','1x'},'RowSpacing',3,'ColumnSpacing',5);
uilabel(pBS,'Text','  Left Brightness'); uilabel(pBS,'Text','  Right Brightness');
uislider(pBS,'Tag','sldBriL','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.over.adjMov,f});
uislider(pBS,'Tag','sldBriR','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.over.adjMov,f});
uilabel(pBS,'Text','  Left Trans (for 3D)','Tag','txtIntTransL','Enable','off');
uilabel(pBS,'Text','  Right Trans (for 3D)','Tag','txtIntTransR','Enable','off');
uislider(pBS,'Tag','sldIntensityTransL','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.over.adjTrans3D,f,'Left'},'Enable','off');
uislider(pBS,'Tag','sldIntensityTransR','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.over.adjTrans3D,f,'Right'},'Enable','off');
pBS.Visible = 'off';
pBrightness.Visible = 'on';

uilabel(bLayer,'Text','  Colorful Overlay Brightness');
uislider(bLayer,'Tag','sldBriOv','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.over.adjMov,f,1});

uilabel(bLayer,'Text','  Overlay Transparency (for 3D)','Tag','txtOvTrans','Enable','off');
uislider(bLayer,'Tag','sldOverlayTrans','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.over.adjTrans3D,f,'Overlay'},'Enable','off');

uilabel(bLayer,'Text','  Downsample XY dimension (for 3D)','Tag','txtDsXY','Enable','off');
uislider(bLayer,'Tag','sldDsXY','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.over.adjDS,f},'Enable','off','Limits',[1,10],'Value',1);

% Channel
pChannel = uigridlayout(bLayer,'Tag','pChannel','Padding',[0,0,0,0],'ColumnWidth',{'1x','1x'},'RowHeight',{'1x','1x'},'RowSpacing',3,'ColumnSpacing',5);
uilabel(pChannel,'Text','Channel in Left view','HorizontalAlignment','center');
uilabel(pChannel,'Text','Channel in Right view','HorizontalAlignment','center');
uidropdown(pChannel,'Tag','channelOptionL','Items',{'Channel 1','Channel 2'},'Value','Channel 1','ValueChangedFcn',{@ui.over.channelOpt,f});
uidropdown(pChannel,'Tag','channelOptionR','Items',{'Channel 1','Channel 2'},'Value','Channel 2','ValueChangedFcn',{@ui.over.channelOpt,f});

% overlays
uilabel(bLayer,'Text','--- Feature overlay ---','HorizontalAlignment','center');
uilabel(bLayer,'Text','  Type');
uidropdown(bLayer,'Tag','overlayDat','Items',{'None'},'ValueChangedFcn',{@ui.over.chgOv,f,1});
uilabel(bLayer,'Text','  Feature');
uidropdown(bLayer,'Tag','overlayFeature','Items',{'Index'},'Enable','off');
uilabel(bLayer,'Text','  Color');
uidropdown(bLayer,'Tag','overlayColor','Items',{'Random','GreenRed','RdBu','RdYlBu','YlGnBu'},'Enable','off');

% uilabel(bLayer,'Text','  Transform');
% uidropdown(bLayer,'Tag','overlayTrans','Items',{'None','Square root','Log10'},'Enable','off');
% uilabel(bLayer,'Text','  Divide');
% uidropdown(bLayer,'Tag','overlayScale','Items',{'None','Size','SqrtSize'},'Enable','off');
% uilabel(bLayer,'Text','  Propagation direction');
% uidropdown(bLayer,'Tag','overlayPropDi','Items', {'Anterior','Posterior','Lateral Left','Lateral Right'},'Enable','off');
% uilabel(bLayer,'Text','  Landmark ID');
% uieditfield(bLayer,'Tag','overlayLmk','Value','1','Enable','off');

bDrawBt = uigridlayout(bLayer,'Padding',[20,0,20,5],'ColumnWidth',{'1x','1x'},'RowHeight',{'1x'},'RowSpacing',5,'ColumnSpacing',5);
uibutton(bDrawBt,'push','Text','Update overlay','Tag','updtFeature','ButtonPushedFcn',{@ui.over.chgOv,f,2});
uibutton(bDrawBt,'push','Text','Update features','Tag','updtFeature1',...
        'ButtonPushedFcn',{@ui.detect.updtFeature,f},'Enable','off');
end





