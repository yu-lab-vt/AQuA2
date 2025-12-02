function CFU_Viewer_Standalone()
    % CFU_Viewer_Standalone: Load CFU results directly.
    % Added 2025/10/02
    
    % 1. Select file
    [filename, pathname] = uigetfile('*.mat', 'Select CFU Result File (_AQuA2_res_cfu.mat)');
    if isequal(filename, 0)
        return;
    end
    fullpath = fullfile(pathname, filename);
    
    disp(['Loading ', fullpath, ' ...']);
    try
        loadedData = load(fullpath);
    catch ME
        errordlg(['Error loading file: ' ME.message], 'Load Error');
        return;
    end

    % 2. Check necessary fields
    if ~isfield(loadedData, 'cfuInfo1') || ~isfield(loadedData, 'datPro')
        errordlg('Selected file does not appear to be a valid AQuA2 CFU result file (missing cfuInfo1 or datPro).', 'Invalid File');
        return;
    end

    % 3. Infer Opts and dimensions (Construct virtual environment)
    datPro = loadedData.datPro;
    [H, W, L] = size(datPro);
    
    % Infer time dimension T
    if ~isempty(loadedData.cfuInfo1)
        T = size(loadedData.cfuInfo1{1,5}, 2);
    else
        T = 1000; % Default
    end
    
    % Construct virtual opts
    opts = struct();
    opts.sz = [H, W, L, T];
    
    % Check single/dual channel
    if isfield(loadedData, 'cfuInfo2') && ~isempty(loadedData.cfuInfo2)
        opts.singleChannel = false;
    else
        opts.singleChannel = true;
    end
    
    % Other opts parameters (virtual values)
    opts.filePath1 = pathname;
    opts.fileName1 = filename;
    opts.movAvgWin = 5; 
    opts.cut = 10;
    opts.minValueDat1 = 0; opts.maxValueDat1 = 1;
    opts.minValueDat2 = 0; opts.maxValueDat2 = 1;

    % 4. Create virtual fOut (Main GUI Handle)
    fOut = uifigure('Name', 'AQuA2 Dummy Main', 'Visible', 'off');
    setappdata(fOut, 'opts', opts);
    
    % Set default button color 'col'
    setappdata(fOut, 'col', [0.94, 0.94, 0.94]); 
    
    % Set Guidata (Background image)
    fhOut = struct();
    fhOut.averPro1 = datPro; 
    
    % Ensure averPro2 exists in fhOut
    if ~opts.singleChannel
        fhOut.averPro2 = datPro; 
        disp('Note: Channel 2 background image is not in the .mat file. Using Channel 1 background for display.');
    else
        fhOut.averPro2 = [];
    end
    
    guidata(fOut, fhOut);
    
    % Set Appdata (UI states)
    btSt = ui.proj.initStates();
    setappdata(fOut, 'btSt', btSt);
    setappdata(fOut, 'bd', containers.Map); 

    % 5. Launch CFU Interface
    fCFU = uifigure('Position', [100, 100, 1200, 800], 'Name', ['CFU Viewer: ', filename]);
    
    try
        ui.com.cfuCon(fCFU, fOut);
    catch ME
        delete(fOut);
        delete(fCFU);
        rethrow(ME);
    end

    % Get handles for further operations
    fh = guidata(fCFU);

    % 6. Inject data (Simulate loadCFUData logic)
    
    % --- Channel 1 Data ---
    setappdata(fCFU, 'cfuInfo1', loadedData.cfuInfo1);
    
    % Reconstruct cfuMap1
    cfuMap1 = zeros(H, W, L, 'uint16');
    nCFU1 = size(loadedData.cfuInfo1, 1);
    for i = 1:nCFU1
        wM = loadedData.cfuInfo1{i,3};
        if numel(wM) == H*W*L
            wM = reshape(wM, H, W, L);
        end
        cfuMap1(wM > 0.1) = uint16(i);
    end
    fh.cfuMap1 = cfuMap1;
    
    % Reconstruct downsampled Map
    dsSclXY = fh.sldDsXY.Value;
    if isempty(dsSclXY) || isnan(dsSclXY), dsSclXY = 1; end
    
    DataDs = se.myResize(zeros(H, W, L, 'single'), 1/dsSclXY);
    overlayLabelDs1 = zeros(size(DataDs), 'uint16');
    cfuShow1 = label2idx(fh.cfuMap1);
    for i = 1:numel(cfuShow1)
        if ~isempty(cfuShow1{i})
            [ih, iw, il] = ind2sub([H, W, L], cfuShow1{i});
            pix0 = unique(sub2ind(size(DataDs), ceil(ih/dsSclXY), ceil(iw/dsSclXY), il));
            overlayLabelDs1(pix0) = uint16(i);
        end
    end
    fh.cfuMapDS1 = overlayLabelDs1;

    % --- Channel 2 Data (if exists) ---
    if ~opts.singleChannel && isfield(loadedData, 'cfuInfo2')
        setappdata(fCFU, 'cfuInfo2', loadedData.cfuInfo2);
        
        cfuMap2 = zeros(H, W, L, 'uint16');
        nCFU2 = size(loadedData.cfuInfo2, 1);
        for i = 1:nCFU2
            wM = loadedData.cfuInfo2{i,3};
            if numel(wM) == H*W*L
                wM = reshape(wM, H, W, L);
            end
            cfuMap2(wM > 0.1) = uint16(i);
        end
        fh.cfuMap2 = cfuMap2;
        
        overlayLabelDs2 = zeros(size(DataDs), 'uint16');
        cfuShow2 = label2idx(fh.cfuMap2);
        for i = 1:numel(cfuShow2)
            if ~isempty(cfuShow2{i})
                [ih, iw, il] = ind2sub([H, W, L], cfuShow2{i});
                pix0 = unique(sub2ind(size(DataDs), ceil(ih/dsSclXY), ceil(iw/dsSclXY), il));
                overlayLabelDs2(pix0) = uint16(i);
            end
        end
        fh.cfuMapDS2 = overlayLabelDs2;
    end
    
    % Relation and Group data
    if isfield(loadedData, 'cfuRelation')
        setappdata(fCFU, 'relation', loadedData.cfuRelation);
        fh.pThr.Enable = 'on';
        fh.minNumCFU.Enable = 'on';
        fh.buttonGroup.Enable = 'on';
    end
    
    if isfield(loadedData, 'cfuGroupInfo')
        setappdata(fCFU, 'groupInfo', loadedData.cfuGroupInfo);
    end

    % 7. [New] Populate UI with saved parameters (cfuOpts)
    % Populates values so users see analysis parameters even if fields are disabled later.
    if isfield(loadedData, 'cfuOpts')
        optsLoaded = loadedData.cfuOpts;
        
        % CFU Detection Params
        if isfield(optsLoaded, 'cfuDetect')
            det = optsLoaded.cfuDetect;
            if isfield(det, 'overlapThr1'), fh.alpha.Value = num2str(det.overlapThr1); end
            if isfield(det, 'minNumEvt1'), fh.minNumEvt.Value = num2str(det.minNumEvt1); end
            
            % Channel 2 Params (if exists)
            if ~opts.singleChannel
                if isfield(det, 'overlapThr2') && isfield(fh, 'alpha2')
                    fh.alpha2.Value = num2str(det.overlapThr2); 
                end
                if isfield(det, 'minNumEvt2') && isfield(fh, 'minNumEvt2')
                    fh.minNumEvt2.Value = num2str(det.minNumEvt2); 
                end
            end
        end
        
        % Analysis Params (Window Size, Shift)
        if isfield(optsLoaded, 'cfuAnalysis')
            ana = optsLoaded.cfuAnalysis;
            if isfield(ana, 'maxDist')
                % Ensure slider is within range (maxDist might exceed default 100)
                fh.sldWinSz.Limits = [0, max(100, ana.maxDist * 1.5)]; 
                fh.sldWinSz.Value = ana.maxDist;
                fh.winSz.Value = num2str(ana.maxDist);
            end
            if isfield(ana, 'shift')
                fh.shift.Value = num2str(ana.shift);
            end
        end
        
        % Group Params
        if isfield(optsLoaded, 'cfuGroup')
            grp = optsLoaded.cfuGroup;
            if isfield(grp, 'pValueThr'), fh.pThr.Value = num2str(grp.pValueThr); end
            if isfield(grp, 'cfuNumThr'), fh.minNumCFU.Value = num2str(grp.cfuNumThr); end
        end
    end

    % Activate toolbar state
    fh.pTool1.Visible = 'on';
    fh.pickButton.Enable = 'on';
    fh.viewButton.Enable = 'on';
    fh.addAllButton.Enable = 'on';
    fh.calDep.Enable = 'on';
    fh.winSz.Enable = 'on';
    fh.sldWinSz.Enable = 'on';
    fh.shift.Enable = 'on';

    % Save guidata and refresh
    guidata(fCFU, fh);
    cfu.updtCFUTable(fCFU);
    cfu.updtGrpTable(fCFU, fOut);
    ui.updtCFUint([], [], fCFU, true); 

    % 8. Disable non-runnable functions
    % Note: Must disable after populating parameters.
    fh = guidata(fCFU);
    
    fh.deOutRun.Enable = 'off';
    fh.deOutRun.Text = 'Run (Disabled)';
    fh.alpha.Enable = 'off';
    fh.minNumEvt.Enable = 'off';
    if isfield(fh, 'alpha2'), fh.alpha2.Enable = 'off'; end
    if isfield(fh, 'minNumEvt2'), fh.minNumEvt2.Enable = 'off'; end
    fh.loadCFUButton.Enable = 'off';
    
    fh.buttonGroup.Enable = 'off';
    fh.buttonGroup.Text = 'Group (Disabled)';
    
    guidata(fCFU, fh);
    
    % 9. Set close callback
    fCFU.CloseRequestFcn = @(src, ~) closeHandlers(src, fOut);
    
    disp('CFU Viewer opened successfully with parameters populated.');
end

function closeHandlers(fCFU, fOut)
    try
        if isvalid(fOut), delete(fOut); end
    catch
    end
    try
        delete(fCFU);
    catch
    end
end