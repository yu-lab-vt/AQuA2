function movPan(src,~,f)
fh = guidata(f);
if src.Value
    fh.Pan.BackgroundColor = [0.8 0.8 0.8];
    fh.Zoom.Value = 0;
    fh.Zoom.BackgroundColor = [0.96 0.96 0.96];
    pause(1e-4);
    pan(f,'on');
    zoom(f,'off');
else
    fh.Pan.BackgroundColor = [0.96 0.96 0.96];
    pause(1e-4);
    pan(f,'off');
end
end