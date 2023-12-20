function select3D(~,~,f)
% get cursor location and run operation specified by op when click movie
%
% Note the difference between image cooridate and matrix coordinate
% For 512 by 512 image, (1,1) in matrix is (1,512) in movie
% Image object begin with (0.5,0.5) to (512.5,512.5)

fh = guidata(f);
opts = getappdata(f,'opts');
btSt = getappdata(f,'btSt');
x = round(fh.xPos.Value);
y = round(fh.yPos.Value);
z = round(fh.zPos.Value);
dsSclXY = fh.sldDsXY.Value;
W0 = fh.xPos.Limits(2);
H0 = fh.yPos.Limits(2);
L0 = fh.zPos.Limits(2);
evtIdx1 = 0;
evtIdx2 = 0;
ov = getappdata(f,'ov');
if ov.isKey('Events_Red')
    ov1 = ov('Events_Red');
    n = round(fh.sldMov.Value);
    labelMap = zeros(H0,W0,L0);
    ov00 = ov1.frame{n};
    if ~isempty(ov00)
        for ii=1:numel(ov00.idx)
            idx1 = ov00.idx(ii);
            [ih,iw,il] = ind2sub([opts.sz(1:3)],ov00.pix{ii});
            pix0 = unique(sub2ind([H0,W0,L0],ceil(ih/dsSclXY),ceil(iw/dsSclXY),il));
            labelMap(pix0) = idx1;
        end
    end
    evtIdx1 = labelMap(y,x,z);
end
fprintf('x %f y %f z%f evtCh1 %d evtCh2 %d\n',x,y,z,evtIdx1,evtIdx2);

if ov.isKey('Events_Green')
    ov1 = ov('Events_Green');
    n = round(fh.sldMov.Value);
    labelMap = zeros(H0,W0,L0);
    ov00 = ov1.frame{n};
    if ~isempty(ov00)
        for ii=1:numel(ov00.idx)
            idx1 = ov00.idx(ii);
            [ih,iw,il] = ind2sub([opts.sz(1:3)],ov00.pix{ii});
            pix0 = unique(sub2ind([H0,W0,L0],ceil(ih/dsSclXY),ceil(iw/dsSclXY),il));
            labelMap(pix0) = idx1;
        end
    end
    evtIdx2 = labelMap(y,x,z);
end
fprintf('x %f y %f z %f evtCh1 %d evtCh2 %d\n',x,y,z,evtIdx1,evtIdx2);

% show curve, add to favourite or delete from favourite
if fh.viewFavClick.Value == 1      
    % add to or remove from event list
    lst1 = btSt.evtMngrMsk1;
    lst2 = btSt.evtMngrMsk2;
    %% channel 1
    if evtIdx1>0
        if isempty(lst1) || sum(lst1==evtIdx1)==0
            lst1 = union(lst1,evtIdx1);            
            ui.evt.curveRefresh([],[],f,evtIdx1,[]);  % draw curve
        else
            lst1 = lst1(lst1~=evtIdx1);                
        end 
        btSt.evtMngrMsk1 = lst1;
        setappdata(f,'btSt',btSt);
        ui.evt.evtMngrRefresh([],[],f);  
    end
    %% channel 2
    if evtIdx2>0
        if isempty(lst2) || sum(lst2==evtIdx2)==0
            lst2 = union(lst2,evtIdx2);            
            ui.evt.curveRefresh([],[],f,[],evtIdx2);  % draw curve
        else
            lst2 = lst2(lst2~=evtIdx2);                
        end 
        btSt.evtMngrMsk2 = lst2;
        setappdata(f,'btSt',btSt);
        ui.evt.evtMngrRefresh([],[],f);  
    end
else
    lst1 = btSt.rmLst1;
    lst2 = btSt.rmLst2;
    %% channel 1
    if evtIdx1>0
        if isempty(lst1) || sum(lst1==evtIdx1)==0
            lst1 = union(lst1,evtIdx1);            
            ui.evt.curveRefresh([],[],f,evtIdx1,[]);  % draw curve
        else
            lst1 = lst1(lst1~=evtIdx1);                
        end
        btSt.rmLst1 = lst1;     
    end
    %% channel 2
    if evtIdx2>0
        if isempty(lst2) || sum(lst2==evtIdx2)==0
            lst2 = union(lst2,evtIdx2);            
            ui.evt.curveRefresh([],[],f,[],evtIdx2);  % draw curve
        else
            lst2 = lst2(lst2~=evtIdx2);                
        end 
        btSt.rmLst2 = lst2;
    end
    setappdata(f,'btSt',btSt);  
    ui.over.updtEvtOvShowLst([],[],f);
end

% refresh movie
ui.movStep(f,[],[],1);

end


