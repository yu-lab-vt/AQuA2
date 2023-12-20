function loadExp(~,~,f)
% cfgFile = 'uicfg.mat';
p0 = '.';
try
    load('./cfg/DefaultFolder.mat');
    if exist(PathName,'dir')
        p0 = PathName;
    end
catch
    p0 = '.';
end

[FileName,PathName] = uigetfile({'*.mat'},'Choose saved results',p0);
if exist('./cfg','dir')
    save('./cfg/DefaultFolder.mat','PathName');
end
if ~isnumeric(FileName)
    setappdata(f,'fexp',[PathName,filesep,FileName]);
    ui.proj.prep([],[],f,1);
end
end