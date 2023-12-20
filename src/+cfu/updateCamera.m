function updateCamera(f,evt)
%UNTITLED15 Summary of this function goes here
%   Detailed explanation goes here
    fh = guidata(f.Parent.Parent.Parent.Parent.Parent);
    movs = {'movL','movR'};
    for i = 1:2
        fh.(movs{i}).CameraPosition = evt.CameraPosition;
        fh.(movs{i}).CameraTarget = evt.CameraTarget;
        fh.(movs{i}).CameraUpVector = evt.CameraUpVector;
        fh.(movs{i}).CameraZoom = evt.CameraZoom;
        pause(1e-4);
    end
end