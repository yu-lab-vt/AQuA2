function ableTemp(~,~,f)
%UNTITLED11 Summary of this function goes here
%   Detailed explanation goes here
fh = guidata(f);
if(fh.needTemp.Value)
    fh.tempSetting.Visible = 'on';
else
    fh.tempSetting.Visible = 'off';
end
end

