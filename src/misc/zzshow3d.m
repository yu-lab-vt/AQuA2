function zzshow3d(data)
    f = uifigure;
    fh = [];
    g = uigridlayout(f);
    
    T = size(data,4);
    g.RowHeight = {'1x',50};
    g.ColumnWidth  = {'1x'};
    pnl = uipanel('Parent',g);
    pnl.Layout.Row = 1;
    viewer = viewer3d(pnl);
    viewer.BackgroundColor = "black";
    viewer.BackgroundGradient = "off";
    % viewer.GradientColor = [0.2,0.2,0.2];
    volIntrinsic = volshow(data(:,:,:,1),'Parent',viewer);%,RenderingStyle="MaximumIntensityProjection",Parent=viewer);
    fh.volIntrinsic = volIntrinsic;
    guidata(f,fh);
    setappdata(f,'data',data);
    
    pnl2 = uipanel(g);
    pnl2.Layout.Row = 2;
    sld = uislider(pnl2,'ValueChangedFcn',@(sld,event) updateSliderBar(sld,event,f));
    sld.Limits = [1,T];
    sld.MajorTicks = [];
    sld.MinorTicks = [];
    sld.MajorTickLabels = {};
    sld.Position = [20,20,500,3];
    
%     for t = 1:T
%         sld.Value = t;
%         fh.volIntrinsic.Data = squeeze(data(:,:,:,round(sld.Value)));
% %         overlayData = zeros(size(data(:,:,:,round(sld.Value))),'uint8');
% %         overlayData(data(:,:,:,round(sld.Value))>105) = 1;
% %         fh.volIntrinsic.OverlayData = overlayData;
%         pause(0.1)
%     end
end