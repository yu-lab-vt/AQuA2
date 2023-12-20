function ableGlo(~,~,f)
%UNTITLED11 Summary of this function goes here
%   Detailed explanation goes here
fh = guidata(f);
if(fh.detectGlo.Value)
    fh.gloSetting.Visible = 'on';
else
    fh.gloSetting.Visible = 'off';
   
end
end

