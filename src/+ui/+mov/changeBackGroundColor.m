function changeBackGroundColor(~,~,f)
fh = guidata(f);
fh.Zoom.Value = 0;
btSt = getappdata(f,'btSt');
if ~isfield(btSt,'bkCol')
    btSt.bkCol = 2;
end

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
btSt.bkCol = mod(btSt.bkCol,size(bkColors,1))+1;

movs = {'mov','movL','movR'};
for i = 1:3
    fh.(movs{i}).BackgroundColor = bkColors(btSt.bkCol,:);
    fh.(movs{i}).GradientColor = gdColors(btSt.bkCol,:);
    pause(1e-4);
end

setappdata(f,'btSt',btSt);
end