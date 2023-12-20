function view3D(~,~,f)
fh = guidata(f);
    opts = fh.opts;
    if opts.singleChannel
        fh.ims.im1.RenderingStyle = 'GradientOpacity';
    else
        fh.ims.im2a.RenderingStyle = 'GradientOpacity';
        pause(1e-4);
        fh.ims.im2b.RenderingStyle = 'GradientOpacity';
    end
end