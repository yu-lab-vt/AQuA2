function updateSlice(src,evt)
%UNTITLED15 Summary of this function goes here
%   Detailed explanation goes here
    f = src.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent;
    fh = guidata(f);
    movs = {'im1','im2a','im2b'};
    fh.xPos.Value = round(double(evt.SlicePlanes(1,4)));
    fh.yPos.Value = round(double(evt.SlicePlanes(2,4)));
    fh.zPos.Value = round(double(evt.SlicePlanes(3,4)));
    for i = 1:3
        fh.ims.(movs{i}).SlicePlaneValues = evt.SlicePlanes;
        pause(1e-4);
    end
    ui.movStep(f);
end