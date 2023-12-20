function adjDS(~,~,f)

fh = guidata(f);
dsSclXY = round(fh.sldDsXY.Value);
fh.sldDsXY.Value = dsSclXY;
ims = {fh.ims.im1,fh.ims.im2a,fh.ims.im2b};
movs = {fh.mov,fh.movL,fh.movR};
opts = getappdata(f,'opts');
Data = se.myResize(zeros(opts.sz(1:3),'single'),1/dsSclXY);

sz = size(Data);
sz = [sz(2),sz(1),sz(3)];
for i = 1:3
    ims{i}.Data = Data;
    movs{i}.CameraPosition = [sz(1)*0.87,sz(2),sum(sz(1:2))/4];
    movs{i}.CameraTarget = (1+sz)/2;
    movs{i}.CameraUpVector = [0,0,1];
    pause(1e-4);
end

fh.xPos.Value = 1; fh.xPos.Limits = [1,sz(1)]; fh.xPos.Value = (1+sz(1))/2;
fh.yPos.Value = 1; fh.yPos.Limits = [1,sz(2)]; fh.yPos.Value = (1+sz(2))/2;
fh.zPos.Value = 1; fh.zPos.Limits = [1,sz(3)]; fh.zPos.Value = (1+sz(3))/2;

ui.over.adjTrans3D([],[],f,'All');

end