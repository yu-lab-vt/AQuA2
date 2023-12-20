function sliceView(~,~,f)
fh = guidata(f);
    opts = fh.opts;
    if opts.singleChannel
        fh.ims.im1.RenderingStyle = 'SlicePlanes';
    else
        fh.ims.im2a.RenderingStyle = 'SlicePlanes';
        pause(1e-4);
        fh.ims.im2b.RenderingStyle = 'SlicePlanes';
    end
end