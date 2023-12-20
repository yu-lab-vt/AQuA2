function advFilters(~,~,f)
%UNTITLED11 Summary of this function goes here
%   Detailed explanation goes here
fh = guidata(f);
if(fh.advFilter.Value)
    fh.gAct3.Visible = 'on';
else
    fh.gAct3.Visible = 'off';
end
end

