function [im1] = uiUpdateFor3D(f,fh,data)

%Change axes to viewer3D
% single view
if strcmp(version('-release'),'2023a')
    fh.Card2.Visible = 'off';
    fh.Card3.Visible = 'on';
    f.Position = getappdata(f,'guiMainSz');
    pause(1);
end

delete(fh.mov);
pMov1 = viewer3d(fh.bMov1Top,'Tag','mov');
pMov1.Layout.Row = 1;
pMov1.BackgroundColor = [0,0,0];
pMov1.BackgroundGradient = "on";
pMov1.GradientColor = [.3,.3,.3];
pMov1.ScaleBar = 'on';
pMov1.Interactions = {'zoom','rotate','pan','axes','slice'};
pMov1.Lighting = 'off';
im1 = volshow(data,'Parent',pMov1);
im1.RenderingStyle = "GradientOpacity";
% im1.AlphaData = ones(size(data),'single')*0.5;
fh.mov = pMov1;
fh.ims.im1 = im1;

if strcmp(version('-release'),'2023a')
    pause(0.5);
end
% side by side view
delete(fh.movL)
pMov2a = viewer3d(fh.bMov2Top,'Tag','movL');
pMov2a.Layout.Row = 2;
pMov2a.Layout.Column = 1;
pMov2a.BackgroundColor = [0,0,0];
pMov2a.BackgroundGradient = "on";
pMov2a.GradientColor = [.3,.3,.3];
pMov2a.ScaleBar = 'on';
pMov2a.Interactions = {'zoom','rotate','pan','axes','slice'};
pMov2a.Lighting = 'off';
im2a = volshow(data,'Parent',pMov2a);
im2a.RenderingStyle = "GradientOpacity";
% im2a.AlphaData = ones(size(data),'single')*0.5;
fh.movL = pMov2a;
fh.ims.im2a = im2a;

if strcmp(version('-release'),'2023a')
    pause(0.5);
end

delete(fh.movR)
pMov2b = viewer3d(fh.bMov2Top,'Tag','movR');
pMov2b.Layout.Row = 2;
pMov2b.Layout.Column = 2;
pMov2b.BackgroundColor = [0,0,0];
pMov2b.BackgroundGradient = "on";
pMov2b.GradientColor = [.3,.3,.3];
pMov2b.ScaleBar = 'on';
pMov2b.Interactions = {'zoom','rotate','pan','axes','slice'};
pMov2b.Lighting = 'off';
im2b = volshow(data,'Parent',pMov2b);
im2b.RenderingStyle = "GradientOpacity";
% im2b.AlphaData = ones(size(data),'single')*0.5;
fh.ims.im2b = im2b;
fh.movR = pMov2b;

% Mask Panel
delete(fh.imgMsk)
pMskMov1 = viewer3d(fh.mskGrid,'Tag','imgMsk');
% pMskMov1.BackgroundColor = bkColors(btSt.bkCol,:);
% pMskMov1.BackgroundGradient = "on";
% pMskMov1.GradientColor = gdColors(btSt.bkCol,:);
pMskMov1.ScaleBar = 'on';
pMskMov1.Interactions = {'zoom','rotate','pan','axes','slice'};
pMskMov1.Lighting = 'off';
imsMsk = volshow(data,'Parent',pMskMov1);
imsMsk.RenderingStyle = "GradientOpacity";
fh.imgMsk = pMskMov1;
fh.imsMsk = imsMsk;


addlistener(pMov1,'CameraMoved',@ui.mov.updateCamera);
addlistener(pMov2a,'CameraMoved',@ui.mov.updateCamera);
addlistener(pMov2b,'CameraMoved',@ui.mov.updateCamera);
addlistener(im1,'SlicePlanesChanged',@ui.mov.updateSlice);
addlistener(im2a,'SlicePlanesChanged',@ui.mov.updateSlice);
addlistener(im2b,'SlicePlanesChanged',@ui.mov.updateSlice);

fh.Pan.Text = 'SliceView';
fh.Pan.ValueChangedFcn = {@ui.mov.sliceView,f};

fh.Zoom.Text = 'switchBackground';
fh.Zoom.ValueChangedFcn = {@ui.mov.changeBackGroundColor,f};

fh.txtIntTrans.Enable = 'on';
fh.sldIntensityTrans.Enable = 'on';
fh.sldIntensityTrans.Limits = [0,1];
fh.sldIntensityTrans.Value = 0.5;
fh.txtIntTransL.Enable = 'on';
fh.sldIntensityTransL.Enable = 'on';
fh.sldIntensityTransL.Limits = [0,1];
fh.sldIntensityTransL.Value = 0.5;
fh.txtIntTransR.Enable = 'on';
fh.sldIntensityTransR.Enable = 'on';
fh.sldIntensityTransR.Limits = [0,1];
fh.sldIntensityTransR.Value = 0.5;
fh.txtOvTrans.Enable = 'on';
fh.sldOverlayTrans.Enable = 'on';
fh.sldOverlayTrans.Limits = [0,1];
fh.sldOverlayTrans.Value = 0.2;
fh.txtIntTransMsk.Enable = 'on';
fh.sldIntensityTransMsk.Enable = 'on';
fh.sldIntensityTransMsk.Limits = [0,1];
fh.sldIntensityTransMsk.Value = 0.5;
fh.txtDsXY.Enable = 'on';
fh.sldDsXY.Enable = 'on';
fh.sldDsXY.Limits = [1,10];
fh.sldDsXY.Value = 1;
fh.txtDsXYMsk.Enable = 'on';
fh.sldDsXYMsk.Enable = 'on';
fh.sldDsXYMsk.Limits = [1,10];
fh.sldDsXYMsk.Value = 1;
fh.whetherExtend.Value = 0;

fh.AddCell.Enable = 'off';
fh.RmCell.Enable = 'off';
fh.DragCell.Enable = 'off';
fh.NameCell.Enable = 'off';
fh.AddLm.Enable = 'off';
fh.RmLm.Enable = 'off';
fh.DragLm.Enable = 'off';
fh.NameLm.Enable = 'off';

fh.drawNorth.Enable = 'off';
fh.checkROI.Enable = 'off';
fh.AddBuilder.Enable = 'off';
fh.RemoveBuilder.Enable = 'off';
fh.Clear.Enable = 'off';
fh.mskBkChangeCol.Enable = 'on';

pause(1e-4);
im1.AlphaData = ones(size(data),'single')*0.5;
pause(1e-4);
im2a.AlphaData = ones(size(data),'single')*0.5;
pause(1e-4);
im2b.AlphaData = ones(size(data),'single')*0.5;
guidata(f,fh);

end