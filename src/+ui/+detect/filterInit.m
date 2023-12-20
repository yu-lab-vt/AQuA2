function filterInit(~,~,f)
    % filterInit initialize filtering table
    
    fh = guidata(f);
    opts = getappdata(f, 'opts');
    fts = getappdata(f,'fts1'); %#ok<NASGU>
    tb = fh.filterTable;
    
    fName = {'Area (um^2)',...
        'dF/F', ...
        'Duration (s)',...
        'P value (dffMax)',...
        'Decay Tau'};
    
    fCmd = {'fts.basic.area',...  % new feature name
        'fts.curve.dffMax',...
        'fts.curve.duration',...
        'fts.curve.dffMaxPval',...
        'fts.curve.decayTau'};
    
    T = cell(numel(fCmd),4);
    for ii=1:numel(fName)
        T{ii,1} = false;
        T{ii,2} = fName{ii};
        cmd0 = ['x=',fCmd{ii},';'];
        try
            eval(cmd0);
            T{ii,3} = min(x);
            T{ii,4} = max(x);
        catch
            fprintf('Feature missed\n')
            T{ii,3} = NaN;
            T{ii,4} = NaN;
        end
    end
    
    if(~opts.singleChannel)
        fts = getappdata(f,'fts2'); %#ok<NASGU>
        for ii=1:numel(fName)
            T{ii,1} = false;
            T{ii,2} = fName{ii};
            cmd0 = ['x=',fCmd{ii},';'];
            try
                eval(cmd0);
                T{ii,3} = min(T{ii,3},min(x));
                T{ii,4} = max(T{ii,4},max(x));
            catch
                fprintf('Feature missed\n')
                T{ii,3} = NaN;
                T{ii,4} = NaN;
            end
        end
    end
    
    tb.Data = T;
    
    btSt = getappdata(f,'btSt');
    btSt.ftsCmd = fCmd;
    setappdata(f,'btSt',btSt);
    
end

