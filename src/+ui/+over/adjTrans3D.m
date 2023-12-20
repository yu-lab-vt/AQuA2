function adjTrans3D(~,~,f,op)

fh = guidata(f);
movs = {'im1','im2a','im2b'};

if strcmp(op,'Overlay')
    for i = 1:3
        fh.ims.(movs{i}).OverlayAlphamap = 1-fh.sldOverlayTrans.Value;
        pause(1e-4);
    end
    return
end

bd = getappdata(f,'bd');
opts = getappdata(f,'opts');
if bd.isKey('cell')
    mask = bd('cell');
else
    mask = true(opts.sz(1:3));
end

dsSclXY = fh.sldDsXY.Value;
alphaMap = zeros(opts.sz(1:3),'single');
alphaMap(mask) = 1;
alphaMap = se.myResize(alphaMap,1/dsSclXY);
trans = [1-fh.sldIntensityTrans.Value,1-fh.sldIntensityTransL.Value,1-fh.sldIntensityTransR.Value];

if strcmp(op,'All')
    for i = 1:3
        fh.ims.(movs{i}).AlphaData = alphaMap*trans(i);
        fh.ims.(movs{i}).OverlayAlphamap = 1-fh.sldOverlayTrans.Value;
        pause(1e-4);
    end    
    ui.movStep(f);
elseif strcmp(op,'Main')
    fh.ims.im1.AlphaData = alphaMap*trans(1);
elseif strcmp(op,'Left')
    fh.ims.im2a.AlphaData = alphaMap*trans(2);
elseif strcmp(op,'Right')
    fh.ims.im2b.AlphaData = alphaMap*trans(3);    
end

end





