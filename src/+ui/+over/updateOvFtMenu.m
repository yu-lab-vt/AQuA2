function updateOvFtMenu(~,~,f)
% updateOvFtMenu update the overlay data type
% only useful when each step of event detection finished

fh = guidata(f);

btSt = getappdata(f,'btSt');
dSel = btSt.overlayDatSel;

ov = getappdata(f,'ov');

ovName0 = ov.keys;
i = 1;
cnt = 0;
ovName = cell(0,1);
while i<=numel(ovName0)
    cnt = cnt + 1;
    curName = ovName0{i};
    if(numel(curName)>5 && strcmp(curName(end-4:end),'Green'))
        ovName{cnt} = curName(1:end-6);
        i = i+1;
    elseif(numel(curName)>3 && strcmp(curName(end-2:end),'Red'))
        ovName{cnt} = curName(1:end-4);
        i = i+1;
    else
        ovName{cnt} = curName;
        i = i+1;
    end
end
ovName = unique(ovName);
% ovName{1} = ovName0{1};
% cnt = 2;
% for i = 2:2:numel(ovName0)
%     ovName{cnt} = ovName0{i}(1:end-6);
%     cnt = cnt + 1;
% end

k = strfind(ovName,dSel);
idx = find(cellfun(@isempty,k)==0,1); %#ok<STRCLFH>

fh.overlayDat.Items = ovName;
fh.overlayDat.Value = fh.overlayDat.Items{idx};

ui.over.chgOv([],[],f,1);

end
