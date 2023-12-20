function adjDS(~,~,f)

fh = guidata(f);
dsSclXY = round(fh.sldDsXYMsk.Value);
fh.sldDsXYMsk.Value = dsSclXY;
opts = getappdata(f,'opts');
Data = se.myResize(zeros(opts.sz(1:3),'single'),1/dsSclXY);
sz = size(Data);
sz = [sz(2),sz(1),sz(3)];
fh.imgMsk.CameraPosition = [sz(1)*0.87,sz(2),sum(sz(1:2))/4];
fh.imgMsk.CameraTarget = (1+sz)/2;
fh.imgMsk.CameraUpVector = [0,0,1];
ui.msk.viewImgMsk([],[],f);
end





