function aqua_gui(res,dbg)
    %AQUA_GUI GUI for AQUA
    warning('off','all')
    startup;

    if ~exist('dbg','var')
        dbg = 0;
    end
    
    f = uifigure('Name','AQUA2','MenuBar','none','Toolbar','none',...
        'NumberTitle','off','Visible','off');
    
    ui.com.addCon(f,dbg);
    if exist('res','var') && ~isempty(res)
        if (ischar(res) || isstring(res)) && exist(res, 'file') == 2   %% 2025/12/11 updated: load from file path
            try
                loadedData = load(res);
                if isfield(loadedData, 'res')
                    res = loadedData.res;
                else
                    warning('AQUA:LoadError', 'res is not found in the loaded file.');
                end
            catch ME
                warning('AQUA:LoadError', ['Error loading file: ', ME.message]);
            end
        end

        ui.proj.prep([],[],f,2,res);
    end
    f.Visible = 'on';
    
end




















