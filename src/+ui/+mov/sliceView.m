function sliceView(~,~,f)
fh = guidata(f);
movs = {'im1','im2a','im2b'};
if fh.Pan.Value
    fh.Pan.BackgroundColor = [0.8 0.8 0.8];
    for i = 1:3
        fh.ims.(movs{i}).RenderingStyle = 'SlicePlanes';
        pause(1e-4);
    end
else
    fh.Pan.BackgroundColor = [0.96 0.96 0.96];
    for i = 1:3
        fh.ims.(movs{i}).RenderingStyle = 'GradientOpacity';
        pause(1e-4);
    end
end
ui.movStep(f);
end