function addCon_toolsMsk(f,pToolMsk)
% masks ***********

% tools panels
bTool = uigridlayout(pToolMsk,'ColumnWidth',{'1x'},'RowHeight',{320},'Padding',[0,10,0,10],'RowSpacing',10);
pThr = uipanel('Parent',bTool);

% thresholding
bMovThr = uigridlayout(pThr,'ColumnWidth',{'1x'},'RowHeight',{20,20,20,20,20,20,20,20,20,20,20,20},'Padding',[0,5,0,0],'RowSpacing',5);
uilabel(bMovThr,'Text','Foreground detection','BackgroundColor',[0 0.3 0.6],'FontColor','white');
uilabel(bMovThr,'Text',' Intensity threshold');
uislider(bMovThr,'Tag','sldMskThr','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.msk.adjMov,f});
uilabel(bMovThr,'Text',' Size (min)');
uislider(bMovThr,'Tag','sldMskMinSz','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.msk.adjMov,f});
uilabel(bMovThr,'Text',' Size (max)');
uislider(bMovThr,'Tag','sldMskMaxSz','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.msk.adjMov,f});
uilabel(bMovThr,'Text',' Erode/Dilate');
uislider(bMovThr,'Tag','sldMskErode_Dilate','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.msk.adjMov,f},'Limits',[-20,20],'Value',0);
uilabel(bMovThr,'Text',' Intensity Transparency (for 3D)','Tag','txtIntTransMsk','Enable','off');
uislider(bMovThr,'Tag','sldIntensityTransMsk','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.msk.adjMov,f},'Enable','off');
uilabel(bMovThr,'Text','  Downsample XY dimension (for 3D)','Tag','txtDsXYMsk','Enable','off');
uislider(bMovThr,'Tag','sldDsXYMsk','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.msk.adjDS,f},'Enable','off','Limits',[1,10],'Value',1);
bEvtBtn = uigridlayout(bMovThr,'ColumnWidth',{'1x'},'RowHeight',{20},'Padding',[20,0,20,0],'RowSpacing',10);
uibutton(bEvtBtn,'push','Text','Change Background Color (for 3D)','ButtonPushedFcn',{@ui.msk.changeBackGroundColor,f},'Enable','off','Tag','mskBkChangeCol');
end








