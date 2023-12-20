% single frame navigation
% Each figure has only one zoom mode object?
function movZoom(src,~,f)
fh = guidata(f);
if src.Value
    fh.Zoom.BackgroundColor = [0.8 0.8 0.8];
    fh.Pan.Value = 0;
    fh.Pan.BackgroundColor = [0.96 0.96 0.96];
    pause(1e-4);
    zoom(f,'on');
    pan(f,'off');
else
    fh.Zoom.BackgroundColor = [0.96 0.96 0.96];
    pause(1e-4);
    zoom(f,'off');
end

end