function sliceMov3D(~,~,f)
    fh = guidata(f);
    movs = {'im1','im2a','im2b'};
    if fh.Pan.Value == 0
        fh.Pan.Value = 1;
        for i = 1:3
            fh.ims.(movs{i}).RenderingStyle = 'SlicePlanes';
            pause(1e-4);
        end
    end
    btSt = getappdata(f,'btSt');
    if isfield(btSt,'isRunning') && btSt.isRunning
        pause(0.1);
        btSt.isRunning = false;
        setappdata(f,'btSt',btSt);
        return;
    end

    fh.xPos.Value = max(min(fh.xPos.Value,fh.xPos.Limits(2)),fh.xPos.Limits(1));
    fh.yPos.Value = max(min(fh.yPos.Value,fh.yPos.Limits(2)),fh.yPos.Limits(1));
    fh.zPos.Value = max(min(fh.zPos.Value,fh.zPos.Limits(2)),fh.zPos.Limits(1));
    slicePlane = [-1,0,0,fh.xPos.Value;0,-1,0,fh.yPos.Value;0,0,-1,fh.zPos.Value];
    
    for i = 1:3
        fh.ims.(movs{i}).SlicePlaneValues = slicePlane;
        pause(1e-4);
    end
    ui.movStep(f);
    btSt.isRunning = false;
    setappdata(f,'btSt',btSt);
end

