function sliceMov3D(~,~,f)
    cfu.sliceView([],[],f);
    fh = guidata(f);
    opts = fh.opts;
    fh.xPos.Value = max(min(fh.xPos.Value,fh.xPos.Limits(2)),fh.xPos.Limits(1));
    fh.yPos.Value = max(min(fh.yPos.Value,fh.yPos.Limits(2)),fh.yPos.Limits(1));
    fh.zPos.Value = max(min(fh.zPos.Value,fh.zPos.Limits(2)),fh.zPos.Limits(1));
    slicePlane = [-1,0,0,fh.xPos.Value;0,-1,0,fh.yPos.Value;0,0,-1,fh.zPos.Value];
    if opts.singleChannel
        fh.ims.im1.SlicePlaneValues = slicePlane;
    else
        fh.ims.im2a.SlicePlaneValues = slicePlane;
        pause(1e-4);
        fh.ims.im2b.SlicePlaneValues = slicePlane;
    end
end

