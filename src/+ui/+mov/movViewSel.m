function movViewSel(src,evt,f)
fh = guidata(f);
btSt = getappdata(f,'btSt');
n = round(fh.sldMov.Value);
if fh.sbs.Value
    btSt.leftView = fh.movLType.Value;
    btSt.rightView = fh.movRType.Value;
end
setappdata(f,'btSt',btSt);

if n>0
    opts = getappdata(f,'opts');
    if ~isempty(evt) && strcmp(evt.PreviousValue(1:3),'Ris') && opts.sz(3)>1  
        bd = getappdata(f,'bd');
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
        if strcmp(src.Tag,'movLType')
            fh.ims.im2a.AlphaData = alphaMap*trans(2);
        else
            fh.ims.im2b.AlphaData = alphaMap*trans(2);
        end
    end

    try
        ui.movStep(f,n,[],1);
    catch
    end
end
end