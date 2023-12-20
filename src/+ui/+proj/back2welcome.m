function back2welcome(~,~,f)
fh = guidata(f);
fh.Card1.Visible = 'on';
fh.Card2.Visible = 'off';
fh.Card3.Visible = 'off';
fh.Card4.Visible = 'off';
f.Position = getappdata(f,'guiWelcomeSz');
f.KeyReleaseFcn = [];
end
