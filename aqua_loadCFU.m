function aqua_loadCFU()

    f = figure('Name','AQUA2-CFU','MenuBar','none','Toolbar','none',...
            'NumberTitle','off','Visible','off');
    
    % top level panels
    g = uix.CardPanel('Parent',f,'Tag','g');
    
    % New proj
    bNew = uix.VBox('Parent',g,'Spacing',5,'Padding',5);
    uix.Empty('Parent',bNew);
    uicontrol('Parent',bNew,'Style','text','String','Result (.mat) Channel 1','HorizontalAlignment','left');
    bNew1 = uix.HBox('Parent',bNew);
    uicontrol('Parent',bNew,'Style','text','String','Result (.mat) Channel 2 (If has two channels)','HorizontalAlignment','left');
    bNew2 = uix.HBox('Parent',bNew);
    uix.Empty('Parent',bNew);
    
    bload = uix.HButtonBox('Parent',bNew,'Spacing',25);
    uicontrol(bload,'String','Open','Callback',{@cfu.load,f});
    bload.ButtonSize = [110,20];
    uix.Empty('Parent',bNew);
    bNew.Heights = [-1,15,20,15,20,15,20,-1];
    % bNew.Heights = [-1,15,20,15,20,15,120,20,-1];
    
    uicontrol(bNew1,'Style','edit','Tag','fIn1','HorizontalAlignment','left');
    uicontrol(bNew1,'String','...','Callback',{@ui.proj.getInputFile1,f});
    bNew1.Widths = [-1,20];
    uicontrol(bNew2,'Style','edit','Tag','fIn2','HorizontalAlignment','left');
    uicontrol(bNew2,'String','...','Callback',{@ui.proj.getInputFile2,f});
    bNew2.Widths = [-1,20];
    
    % default GUI settings
    fh = guihandles(f);
    fh.Card1.Visible = 'on';
    fh.Card2.Visible = 'off';
    fh.Card3.Visible = 'off';
    fh.Card4.Visible = 'off';    
    guidata(f,fh);
    
    Pix_SS = get(0,'screensize');
    h0 = Pix_SS(4)+22; w0 = Pix_SS(3);  % 50 is taskbar size
    setappdata(f,'guiWelcomeSz',[w0/2-200,h0/2-150,400,300]);
    setappdata(f,'guiMainSz',[w0/2-700 h0/2-400 1400 850]);
    
    f.Position = getappdata(f,'guiWelcomeSz');
    f.CloseRequestFcn = {@ui.proj.closeMe,f};
    f.Visible = 'on';
end


