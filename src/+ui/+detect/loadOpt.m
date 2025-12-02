function loadOpt(~,~,f)
% Updated 2025/12/2: Load from the format of parameters.csv template, and update UI
    
    opts = getappdata(f,'opts');
    
    % Select file
    [file,path] = uigetfile('*.csv','Choose Parameter file',opts.filePath1);
    if isequal(file,0), return; end
    
    fullPath = fullfile(path, file);
    
    try
        % --- 1. Read using readtable ---
        T = readtable(fullPath, 'PreserveVariableNames', true);
        
        % Identify value column: prioritize 'Value', then 'Default', else 4th column
        colNames = T.Properties.VariableNames;
        valColName = '';
        
        if any(strcmp('Value', colNames))
            valColName = 'Value';
        elseif any(strcmp('Default', colNames))
            valColName = 'Default';
        else
            if width(T) >= 4
                valColName = colNames{4};
            else
                error('Cannot determine value column in the CSV file.');
            end
        end
        
        % --- 2. Parse table to opts ---
        nRows = height(T);
        for i = 1:nRows
            varName = T.Variable{i};
            
            % Skip invalid rows
            if isempty(varName) || any(ismissing(varName)) || (iscell(varName) && isempty(varName{1}))
                continue;
            end
            if iscell(varName), varName = varName{1}; end
            
            % Read value
            rawVal = T.(valColName)(i);
            if iscell(rawVal), rawVal = rawVal{1}; end
            
            % Convert data type (numeric or string)
            val = [];
            if isnumeric(rawVal)
                val = rawVal;
            elseif ischar(rawVal) || isstring(rawVal)
                % Try converting to number
                numVal = str2double(rawVal);
                if ~isnan(numVal)
                    val = numVal;
                else
                    val = rawVal; % Keep as string
                end
            end
            
            % Update opts
            opts.(varName) = val;
        end
        
        % Save updated opts
        setappdata(f,'opts',opts);
        
        % --- 3. Update UI (Full Parameter List) ---
        fh = guidata(f);
        
        % Preprocessing
        try fh.registrateCorrect.Value = fh.registrateCorrect.Items{opts.registrateCorrect}; catch; end
        try fh.bleachCorrect.Value = fh.bleachCorrect.Items{opts.bleachCorrect}; catch; end
        fh.medSmo.Value = num2str(opts.medSmo);
        fh.smoXY.Value = num2str(opts.smoXY);

        % Active Region
        fh.thrArScl.Value = num2str(opts.thrARScl);
        fh.minSize.Value = num2str(opts.minSize);
        fh.maxSize.Value = num2str(opts.maxSize);
        fh.circularityThr.Value = num2str(opts.circularityThr);
        fh.minDur.Value = num2str(opts.minDur);
        try fh.spaMergeDist.Value = num2str(opts.spaMergeDist); catch; end;
        
        % Temporal
        fh.needTemp.Value = opts.needTemp;
        fh.seedSzRatio.Value = num2str(opts.seedSzRatio);
        fh.sigThr.Value = num2str(opts.sigThr);
        fh.maxDelay.Value = num2str(opts.maxDelay);
        % fh.needRefine / needGrow deprecated in some versions, skip
        
        % Spatial
        fh.needSpa.Value = opts.needSpa;
        fh.sourceSzRatio.Value = num2str(opts.sourceSzRatio);
        fh.sourceSensitivity.Value = num2str(opts.sourceSensitivity);
        try fh.whetherExtend.Value = opts.whetherExtend; catch; end

        % Global / Post
        fh.detectGlo.Value = opts.detectGlo;
        fh.gloDur.Value = num2str(opts.gloDur);
        fh.ignoreTau.Value = opts.ignoreTau;
        fh.propMetric.Value = opts.propMetric;
        fh.networkFeatures.Value = opts.networkFeatures;
        
        % Update Advanced Parameters (use try-catch for hidden/missing controls)
        try fh.gtwSmo.Value = num2str(opts.gtwSmo); catch; end
        try fh.ratio.Value = num2str(opts.ratio); catch; end
        try fh.regMaskGap.Value = num2str(opts.regMaskGap); catch; end
        try fh.cut.Value = num2str(opts.cut); catch; end
        try fh.movAvgWin.Value = num2str(opts.movAvgWin); catch; end
        try fh.minShow1.Value = num2str(opts.minShow1); catch; end
        try fh.correctTrend.Value = num2str(opts.correctTrend); catch; end
        try fh.propthrmin.Value = num2str(opts.propthrmin); catch; end
        try fh.propthrmax.Value = num2str(opts.propthrmax); catch; end
        try fh.propthrstep.Value = num2str(opts.propthrstep); catch; end
        try fh.compress.Value = num2str(opts.compress); catch; end
        try fh.gapExt.Value = num2str(opts.gapExt); catch; end
        try fh.frameRate.Value = num2str(opts.frameRate); catch; end
        try fh.spatialRes.Value = num2str(opts.spatialRes); catch; end
        try fh.northx.Value = num2str(opts.northx); catch; end
        try fh.northy.Value = num2str(opts.northy); catch; end
        try fh.TPatch.Value = num2str(opts.TPatch); catch; end
        try fh.maxSpaScale.Value = num2str(opts.maxSpaScale); catch; end
        try fh.minSpaScale.Value = num2str(opts.minSpaScale); catch; end

        % Refresh Movie Info (if slider exists)
        if isfield(fh, 'sldMov')
            n = round(fh.sldMov.Value);
            ui.mov.updtMovInfo(f,n,opts.sz(4));
        end
        
        disp(['Parameters loaded from ', file]);

    catch ME
        errordlg(['Error loading parameter file: ', ME.message]);
    end
end