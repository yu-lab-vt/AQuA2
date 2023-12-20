function ableSpa(~,~,f)
%UNTITLED11 Summary of this function goes here
%   Detailed explanation goes here
fh = guidata(f);
if(fh.needSpa.Value)
    fh.spaSetting.Visible = 'on';
else
    fh.spaSetting.Visible = 'off';
   
end
end

