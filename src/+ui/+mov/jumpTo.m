function jumpTo(~,~,f)
fh = guidata(f);
try
    n = str2double(fh.jumpTo.Value);
catch
    msgbox('Invalid number');
end
fh.sldMov.Value = n;
ui.movStep(f,n,[],1);
end