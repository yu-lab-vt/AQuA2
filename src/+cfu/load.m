function load(~,~,f)

fprintf('Loading ...\n');
ff = waitbar(0,'Loading ...');


fh = guidata(f);

% new project

try
    res = load(fh.fIn1.Value);
    res = res.res;
    opts = res.opts;
    opts.maxValueDat1 = 1;
    opts.maxValueDat2 = 1;
    opts.minValueDat1 = 0;
    opts.minValueDat2 = 0;
    setappdata(f, 'datOrg1',sqrt(single(res.datOrg1)));
    setappdata(f, 'evt1',res.evt1);
    setappdata(f, 'dF1',res.dF1)
    setappdata(f, 'fts1',res.fts1)
    
    fh = guidata(f);
    fh.averPro1 = mean(getappdata(f, 'datOrg1'),3);    
    fh.averPro2 = [];
    clear res;
    if ~isempty(fh.fIn2.Value)
        res2 = load(fh.fIn2.Value);
        res2 = res2.res;
        opts.singleChannel = false;
        setappdata(f, 'datOrg2',sqrt(single(res2.datOrg1)));
        setappdata(f, 'evt2',res2.evt1);
        setappdata(f, 'dF2',res2.dF1)
        setappdata(f, 'fts2',res2.fts1)
        fh.averPro2 = mean(getappdata(f, 'datOrg2'),3);  
        clear res2;
    end
    guidata(f,fh);
    setappdata(f, 'opts',opts)
catch
    msgbox('Fail to load file');
    return
end
setappdata(f,'col',[0.3,0.3,0.7]);
fCFU = figure('Name','AQUA2-CFU','MenuBar','none','Toolbar','none',...
        'NumberTitle','off','Visible','off');
ui.com.cfuCon(fCFU,f);
fCFU.Visible = 'on';
f.Visible = 'off';

waitbar(1,ff);

% UI

fprintf('Done ...\n');
delete(ff);

end











