function showDetails(~,~,f)
    
    % use a GUI to display detailed features
    opts = getappdata(f,'opts');
    ftb1 = getappdata(f,'featureTable1');
    btSt = getappdata(f,'btSt');
    
    lst1 = btSt.evtMngrMsk1;
    ftb00 = ftb1{:,1};
    Event_favorite = ftb00(:,lst1);
    
    if(~opts.singleChannel)
        ftb2 = getappdata(f,'featureTable2');
        lst2 = btSt.evtMngrMsk2;
        ftb00 = ftb2{:,1};
        Event_favorite = [Event_favorite,ftb00(:,lst1)];
        
    end
    
    
    ftsRowName = ftb1.Row;
    
    % initialize GUI
    figFav = getappdata(f,'figFav');
    if isempty(figFav) || ~isvalid(figFav)
        figFav = uifigure('MenuBar','none','Toolbar','none','NumberTitle','off');
        figFav.Name = 'Features for favorite events';
        Pix_SS = get(0,'screensize');
        h0 = Pix_SS(4)/2-350; w0 = Pix_SS(3)/2-350;  % 50 is taskbar size
        figFav.Position = [w0,h0,700,700];
        b00 = uipanel('Parent',figFav,'Units','normalized','Position',[0,0,1,1],'BorderType','none');
%         g = uigridlayout(b00);
        tb = uitable(b00,'Tag','evtFavTab','Position',[10,10,680,680]);
        fh00 = guihandles(figFav);
        guidata(figFav,fh00);
        setappdata(f,'figFav',figFav);
    end
    
    % put to table
    fh00 = guidata(figFav);
    tb00 = fh00.evtFavTab;
    tb00.Data = [ftsRowName, Event_favorite];
    nCol = size(tb00.Data,2);
    colWidth = cell(1,nCol);
    colWidth{1} = 270;
    for ii=2:nCol
        colWidth{ii} = 'auto';
    end
    tb00.ColumnWidth = colWidth;
    
end