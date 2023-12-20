function movSideBySide(~,~,f)
fh = guidata(f);
n = round(fh.sldMov.Value);

if fh.sbs.Value
    fh.sbs.BackgroundColor = [0.8 0.8 0.8];
    fh.bMov1Top.Visible = 'off';
    fh.bMov2Top.Visible = 'on';
    fh.pBrightness.Visible = 'off';
    fh.pBrightnessSideBySide.Visible = 'on';
else
    fh.sbs.BackgroundColor = [0.96 0.96 0.96];
    fh.bMov1Top.Visible = 'on';
    fh.bMov2Top.Visible = 'off';
    fh.pBrightness.Visible = 'on';
    fh.pBrightnessSideBySide.Visible = 'off';
end
pause(1e-4);
if n>0
%     ui.over.adjMov([],[],f,1)
    ui.movStep(f,n,[],1);
end
end