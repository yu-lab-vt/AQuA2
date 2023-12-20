function changeBackGroundColor(~,~,f)
fh = guidata(f);
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
fh.bkColMsk = mod(fh.bkColMsk,size(bkColors,1))+1;

fh.imgMsk.BackgroundColor = bkColors(fh.bkColMsk,:);
fh.imgMsk.GradientColor = gdColors(fh.bkColMsk,:);
guidata(f,fh);

end