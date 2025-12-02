function saveOpt(~,~,f)
% Updated 2025/12/2: Save as the format of parameters.csv template

    % Retrieve original opts as base
    optsOrg = getappdata(f,'opts');
    fh = guidata(f);
    
    % --- 1. Collect current parameters into temp opts struct ---
    opts = optsOrg; % Inherit background parameters
    
    % Dropdowns
    opts.registrateCorrect = find(strcmp(fh.registrateCorrect.Value,fh.registrateCorrect.Items));
    if isempty(opts.registrateCorrect), opts.registrateCorrect = 1; end
    opts.bleachCorrect = find(strcmp(fh.bleachCorrect.Value,fh.bleachCorrect.Items));
    if isempty(opts.bleachCorrect), opts.bleachCorrect = 1; end
    
    % Numeric Fields
    opts.medSmo = str2double(fh.medSmo.Value);
    opts.smoXY = str2double(fh.smoXY.Value);
    opts.thrARScl = str2double(fh.thrArScl.Value);
    opts.minSize = str2double(fh.minSize.Value);
    opts.maxSize = str2double(fh.maxSize.Value);
    opts.minDur = str2double(fh.minDur.Value);
    opts.circularityThr = str2double(fh.circularityThr.Value);
    
    % Handle spaMergeDist (inherit or set default)
    if isfield(optsOrg, 'spaMergeDist')
        opts.spaMergeDist = optsOrg.spaMergeDist;
    else
        opts.spaMergeDist = 0; 
    end
    
    opts.needTemp = fh.needTemp.Value;
    opts.sigThr = str2double(fh.sigThr.Value);
    opts.maxDelay = str2double(fh.maxDelay.Value);
    opts.seedSzRatio = str2double(fh.seedSzRatio.Value);
    
    opts.needSpa = fh.needSpa.Value;
    opts.sourceSzRatio = str2double(fh.sourceSzRatio.Value);
    opts.sourceSensitivity = str2double(fh.sourceSensitivity.Value);
    try opts.whetherExtend = fh.whetherExtend.Value; catch; end

    opts.detectGlo = fh.detectGlo.Value;
    opts.gloDur = str2double(fh.gloDur.Value);

    opts.ignoreTau = fh.ignoreTau.Value;
    opts.propMetric = fh.propMetric.Value;
    opts.networkFeatures = fh.networkFeatures.Value;
    
    % --- 2. Read template and build table ---
    try
        % Load configuration template for structure
        cfgPath = './cfg/parameters.csv';
        if ~exist(cfgPath, 'file')
            error('Configuration template ./cfg/parameters.csv not found.');
        end
        
        T_template = readtable(cfgPath, 'PreserveVariableNames', true);
        
        % Prepare new data column
        nRows = height(T_template);
        ValueCol = cell(nRows, 1);
        
        % Populate values from opts into template
        for i = 1:nRows
            varName = T_template.Variable{i};
            
            % Check for empty or missing variable names
            if isempty(varName) || any(ismissing(varName))
                ValueCol{i} = '';
                continue;
            end
            
            % Convert string to char for struct field usage
            if isstring(varName)
                varName = char(varName);
            end
            
            % Fill value if it exists in opts
            if isfield(opts, varName)
                val = opts.(varName);
                if isnumeric(val)
                    ValueCol{i} = num2str(val);
                elseif islogical(val)
                    ValueCol{i} = num2str(double(val));
                else
                    ValueCol{i} = char(string(val));
                end
            else
                ValueCol{i} = ''; 
            end
        end
        
        % Build output table
        T_out = table();
        
        % Safely retrieve columns
        if any(strcmp('Name', T_template.Properties.VariableNames))
            T_out.Name = T_template.Name;
        else
            T_out.Name = repmat({''}, nRows, 1);
        end
        
        T_out.Variable = T_template.Variable;
        
        if any(strcmp('Type', T_template.Properties.VariableNames))
            T_out.Type = T_template.Type;
        else
             T_out.Type = repmat({''}, nRows, 1);
        end
        
        T_out.Value = ValueCol;
        
        if any(strcmp('Notes', T_template.Properties.VariableNames))
            T_out.Notes = T_template.Notes;
        else
             T_out.Notes = repmat({''}, nRows, 1);
        end
        
    catch ME
        errordlg(['Error preparing parameter table: ' ME.message]);
        return;
    end
    
    % --- 3. Save file ---
    definput = {'_Opt.csv'};
    selname = inputdlg('Type desired suffix for Parameter file name:',...
        'Parameter file',[1 75],definput);
    
    if isempty(selname)
        return; 
    end
    selname = char(selname);
    
    if isempty(optsOrg.fileName1)
        baseName = 'Experiment';
    else
        [~, baseName, ~] = fileparts(optsOrg.fileName1);
    end
    
    file0 = [baseName, selname];
    if ~endsWith(file0, '.csv', 'IgnoreCase', true)
        file0 = [file0, '.csv'];
    end
    
    selpath = uigetdir(optsOrg.filePath1,'Choose output folder');
    if isnumeric(selpath), return; end % Cancelled
    
    fullSavePath = fullfile(selpath, file0);
    
    try
        writetable(T_out, fullSavePath);
        disp(['Parameters saved to: ', fullSavePath]);
    catch ME
        errordlg(['Failed to save file: ', ME.message]);
    end
end