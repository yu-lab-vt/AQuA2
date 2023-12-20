function changeBackGroundColor(~,~,fCFU,f)
fh = guidata(fCFU);
opts = getappdata(f,'opts');
bkColors = [0,0,0;
    0,0,0;
    0 0.3290 0.5290;
    .5,.5,.5;
    1,1,1];
gdColors = [0,0,0;
    .3,.3,.3;
    0 0.5610 1;
    .8,.8,.8;
    1,1,1];
fh.bkCol = mod(fh.bkCol,size(bkColors,1))+1;

if opts.singleChannel
    fh.mov.BackgroundColor = bkColors(fh.bkCol,:);
    fh.mov.GradientColor = gdColors(fh.bkCol,:);
else
    fh.movL.BackgroundColor = bkColors(fh.bkCol,:);
    fh.movL.GradientColor = gdColors(fh.bkCol,:);
    pause(1e-4);
    fh.movR.BackgroundColor = bkColors(fh.bkCol,:);
    fh.movR.GradientColor = gdColors(fh.bkCol,:);
end
guidata(fCFU,fh);

end