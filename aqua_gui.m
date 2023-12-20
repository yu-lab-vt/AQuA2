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
        ui.proj.prep([],[],f,2,res);
    end
    f.Visible = 'on';
    
end




















