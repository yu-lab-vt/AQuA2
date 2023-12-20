function adjDS(~,~,f)

fh = guidata(f);
opts = getappdata(f,'opts');
dsSclXY = round(fh.sldDsXY.Value);
fh.sldDsXY.Value = dsSclXY;
opts = fh.opts;
Data = se.myResize(zeros(opts.sz(1:3),'single'),1/dsSclXY);
sz = size(Data);
sz = [sz(2),sz(1),sz(3)];
if opts.singleChannel
    fh.mov.CameraPosition = [sz(1)*0.87,sz(2),sum(sz(1:2))/4];
    fh.mov.CameraTarget = (1+sz)/2;
    fh.mov.CameraUpVector = [0,0,1];
else
    fh.movL.CameraPosition = [sz(1)*0.87,sz(2),sum(sz(1:2))/4];
    fh.movL.CameraTarget = (1+sz)/2;
    fh.movL.CameraUpVector = [0,0,1];
    fh.movR.CameraPosition = [sz(1)*0.87,sz(2),sum(sz(1:2))/4];
    fh.movR.CameraTarget = (1+sz)/2;
    fh.movR.CameraUpVector = [0,0,1];
end

overlayLabelDs = zeros(size(Data),'uint16');
if isfield(fh,'cfuMap1')
    cfuShow = label2idx(fh.cfuMap1);
    for i = 1:numel(cfuShow)
        if ~isempty(cfuShow{i})
            [ih,iw,il] = ind2sub([opts.sz(1:3)],cfuShow{i});
            pix0 = unique(sub2ind(size(Data),ceil(ih/dsSclXY),ceil(iw/dsSclXY),il));
            overlayLabelDs(pix0) = i;
        end
    end
end
fh.cfuMapDS1 = overlayLabelDs;

if ~opts.singleChannel
    overlayLabelDs = zeros(size(Data),'uint16');
    if isfield(fh,'cfuMap2')
        cfuShow = label2idx(fh.cfuMap2);
        for i = 1:numel(cfuShow)
            if ~isempty(cfuShow{i})
                [ih,iw,il] = ind2sub([opts.sz(1:3)],cfuShow{i});
                pix0 = unique(sub2ind(size(Data),ceil(ih/dsSclXY),ceil(iw/dsSclXY),il));
                overlayLabelDs(pix0) = i;
            end
        end
    end
    fh.cfuMapDS2 = overlayLabelDs;
else
    fh.cfuMapDS2 = [];
end
guidata(f,fh);

ui.updtCFUint([],[],f,false);
fh.xPos.Value = 1; fh.xPos.Limits = [1,sz(1)]; fh.xPos.Value = (1+sz(1))/2;
fh.yPos.Value = 1; fh.yPos.Limits = [1,sz(2)]; fh.yPos.Value = (1+sz(2))/2;
fh.zPos.Value = 1; fh.zPos.Limits = [1,sz(3)]; fh.zPos.Value = (1+sz(3))/2;
opts = fh.opts;
slicePlane = [-1,0,0,fh.xPos.Value;0,-1,0,fh.yPos.Value;0,0,-1,fh.zPos.Value];
if opts.singleChannel
    fh.ims.im1.SlicePlaneValues = slicePlane;
else
    fh.ims.im2a.SlicePlaneValues = slicePlane;
    pause(1e-4);
    fh.ims.im2b.SlicePlaneValues = slicePlane;
end
cfu.view3D([],[],f);
end





