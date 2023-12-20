function addCon_proj(f,bWel,bNew)
% Welcome
uibutton(bWel,'push','Text','New project','ButtonPushedFcn',{@ui.proj.newProj,f},'FontSize',18);
uibutton(bWel,'push','Text','Load existing','ButtonPushedFcn',{@ui.proj.loadExp,f},'FontSize',18);

% New proj
bNew1 = uigridlayout(bNew,'ColumnWidth',{'1x',20},'RowHeight',{15,20,15,20},'Padding',[0,0,0,0],'ColumnSpacing',5,'RowSpacing',5);
p = uilabel(bNew1,'Text','Movie (TIFF stack) Channel 1 (If only one channel, please add path here)');
p.Layout.Column = [1,2];
uieditfield(bNew1,'text','Tag','fIn1');
uibutton(bNew1,'push','Text','...','ButtonPushedFcn',{@ui.proj.getInputFile1,f});
p = uilabel(bNew1,'Text','Movie (TIFF stack) Channel 2');
p.Layout.Column = [1,2];
uieditfield(bNew1,'text','Tag','fIn2');
uibutton(bNew1,'push','Text','...','ButtonPushedFcn',{@ui.proj.getInputFile2,f});

% event detection: data settings
pDeProp = uigridlayout(bNew,'ColumnWidth',{100,'1x'},'RowHeight',{20,20,20,20},'Padding',[0,0,0,15],'ColumnSpacing',5,'RowSpacing',5);
uidropdown(pDeProp,'Tag','preset','ValueChangedFcn',{@ui.proj.updtPreset,f});
uilabel(pDeProp,'Text','Data type (presets)');
uieditfield(pDeProp,'Value','1','Tag','tmpRes');
uilabel(pDeProp,'Text','Temporal resolution: second per frame');
uieditfield(pDeProp,'Value','1','Tag','spaRes');
uilabel(pDeProp,'Text','Spatial resolution: um per pixel');
uieditfield(pDeProp,'Value','2','Tag','bdSpa');
uilabel(pDeProp,'Text','Exclude pixels shorter than this distance to border');

bload = uigridlayout(bNew,'ColumnWidth',{'1x','1x','1x'},'RowHeight',{'1x'},'Padding',[10,5,10,15],'ColumnSpacing',25,'RowSpacing',5);
uibutton(bload,'push','Text','< Back','ButtonPushedFcn',{@ui.proj.welcome,f});
uibutton(bload,'push','Text','Open','ButtonPushedFcn',{@ui.proj.prep,f});
uibutton(bload,'push','Text','Load presets','ButtonPushedFcn',{@ui.proj.updtPreset,f});

end



