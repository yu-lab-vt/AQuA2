function adjMov(~,~,f,updtOv)

if ~exist('updtOv','var')
    updtOv = 1;
end

fh = guidata(f);
scl = getappdata(f,'scl');
opts = getappdata(f,'opts');
scl.min = fh.sldMin.Value;
scl.max = fh.sldMax.Value;
scl.bri1 = fh.sldBri1.Value;
if ~opts.singleChannel
    scl.bri2 = fh.sldBri2.Value;
end
scl.briL = fh.sldBriL.Value;
scl.briR = fh.sldBriR.Value;
scl.briOv = fh.sldBriOv.Value;
setappdata(f,'scl',scl);


if opts.sz(3) > 1
    movs = {'im1','im2a','im2b'};
    brights = [scl.bri1, scl.briL, scl.briR];
    for i = 1:3
        fh.ims.(movs{i}).Colormap = max(min(gray(256)*brights(i),1),0);
        pause(1e-4);
    end
end

% use current overlay colormap
% do not include rising time map
if updtOv
    btSt = getappdata(f,'btSt');
    ov = getappdata(f,'ov');
    if(strcmp(btSt.overlayDatSel,'None'))
        ov1 = [];
        ov2 = [];
    else
        ov1 = ov([btSt.overlayDatSel,'_Red']);
        ov2 = ov([btSt.overlayDatSel,'_Green']);
    end
    if isfield(ov1,'colVal') && strcmp(btSt.overlayColorSel,'Random')==0
        v1 = ov1.colVal;
        gap1 = (max(v1)-min(v1))/99;
        m1 = min(v1):gap1:max(v1);
        cMap0 = ui.over.reMapCol(btSt.mapNow,m1,scl);        
        if ~fh.sbs.Value
            ui.over.updtColMap(fh.movColMap,m1,cMap0,1);
        else
            viewName = {'leftView','rightView'};
            axLst = {fh.movLColMap,fh.movRColMap};
            for ii=1:2
                curType = btSt.(viewName{ii});
                axNow = axLst{ii};
                if strcmp(curType,'Raw + overlay')
                    ui.over.updtColMap(axNow,m1,cMap0,1);
                else
                    ui.over.updtColMap(axNow,[],[],0);
                end
            end
        end
    else
        cMapLst = {'movColMap','movLColMap','movRColMap'};
        for ii=1:3
            ui.over.updtColMap(fh.(cMapLst{ii}),[],[],0);
        end
    end
end

ui.movStep(f);

end





