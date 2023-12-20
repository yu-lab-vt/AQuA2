function welcome(~,~,f)
fh = guidata(f);
% keyboard
f.KeyReleaseFcn = [];
fh.Card1.Visible = 'on';
fh.Card2.Visible = 'off';
fh.Card3.Visible = 'off';
fh.Card4.Visible = 'off';
% f.Resize = 'off';
end