function getInputFile1(~,~,f)
fh = guidata(f);
p0 = '.';
try
    load('./cfg/DefaultFolder.mat');
    if exist(PathName,'dir')
        p0 = PathName;
    end
catch
    p0 = '.';
end

[FileName,PathName] = uigetfile({'*.tif;*.mat;*.tiff'},'Choose movie',p0);
if exist('./cfg','dir')
    save('./cfg/DefaultFolder.mat','PathName');
end

if ~isempty(FileName) && ~isnumeric(FileName)
    fh.fIn1.Value = [PathName,FileName];
end

f.Visible = 'off';
f.Visible = 'on';

end
