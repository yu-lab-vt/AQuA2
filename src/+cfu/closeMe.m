function closeMe(~,~,f)
    % Close request function
    % to display a question dialog box
    
    selection = questdlg('Quit?',...
        'Close Request Function',...
        'Yes','No','No');
    switch selection
        case 'Yes'
            delete(f)
        case 'No'
            return
    end
end