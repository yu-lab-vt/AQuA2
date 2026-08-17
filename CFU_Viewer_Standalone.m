function CFU_Viewer_Standalone()
%CFU_Viewer_Standalone Open a saved AQuA2 CFU result in a read-only viewer.

    [filename, pathname] = uigetfile('*.mat', ...
        'Select CFU Result File (_AQuA2_res_cfu.mat)');
    if isequal(filename, 0)
        return;
    end

    fullPath = fullfile(pathname, filename);
    try
        loadedData = load(fullPath);
    catch ME
        errordlg(['Error loading file: ' ME.message], 'Load Error');
        return;
    end

    if ~isfield(loadedData, 'cfuInfo1') || ~isfield(loadedData, 'datPro')
        errordlg(['Selected file does not appear to be a valid AQuA2 CFU ' ...
            'result file (missing cfuInfo1 or datPro).'], 'Invalid File');
        return;
    end

    opts = buildViewerOptions(loadedData, pathname, filename);
    fOut = createViewerContext(loadedData.datPro, opts);
    fCFU = uifigure('Position', [100, 100, 1200, 800], ...
        'Name', ['CFU Viewer: ', filename]);

    try
        ui.com.cfuCon(fCFU, fOut);
        % Reuse the main CFU loader so data reconstruction, parameter
        % restoration, saved boundaries, and future format changes remain
        % identical in the viewer and the primary application.
        [didLoad, ~] = cfu.loadCFUData([], [], fCFU, fOut, loadedData);
        if ~didLoad
            closeViewer(fCFU, fOut);
            return;
        end
        setViewerReadOnly(fCFU);
    catch ME
        closeViewer(fCFU, fOut);
        rethrow(ME);
    end

    fCFU.CloseRequestFcn = @(src, ~) closeViewer(src, fOut);
    disp('CFU Viewer opened successfully.');
end

function opts = buildViewerOptions(loadedData, pathname, filename)
%buildViewerOptions Create the minimal main-GUI configuration for a result.

    datPro = loadedData.datPro;
    [height, width, depth] = size(datPro);
    if isempty(loadedData.cfuInfo1)
        timePoints = 1000;
    else
        timePoints = size(loadedData.cfuInfo1{1, 5}, 2);
    end

    opts = struct();
    opts.sz = [height, width, depth, timePoints];
    opts.singleChannel = ~isfield(loadedData, 'cfuInfo2') || isempty(loadedData.cfuInfo2);
    opts.filePath1 = pathname;
    opts.fileName1 = filename;
    opts.movAvgWin = 5;
    opts.cut = 10;
    opts.minValueDat1 = 0;
    opts.maxValueDat1 = 1;
    opts.minValueDat2 = 0;
    opts.maxValueDat2 = 1;
end

function fOut = createViewerContext(datPro, opts)
%createViewerContext Create the hidden main-GUI context needed by cfuCon.

    fOut = uifigure('Name', 'AQuA2 Dummy Main', 'Visible', 'off');
    setappdata(fOut, 'opts', opts);
    setappdata(fOut, 'col', [0.94, 0.94, 0.94]);
    setappdata(fOut, 'btSt', ui.proj.initStates());
    setappdata(fOut, 'bd', containers.Map);

    fhOut = struct();
    fhOut.averPro1 = datPro;
    if opts.singleChannel
        fhOut.averPro2 = [];
    else
        % CFU result files retain one processed background image only.
        fhOut.averPro2 = datPro;
    end
    guidata(fOut, fhOut);
end

function setViewerReadOnly(fCFU)
%setViewerReadOnly Disable actions that require the unavailable source data.

    if ~isgraphics(fCFU)
        return;
    end
    fh = guidata(fCFU);
    fh.deOutRun.Enable = 'off';
    fh.deOutRun.Text = 'Run (Disabled)';
    fh.alpha.Enable = 'off';
    fh.minNumEvt.Enable = 'off';
    if isfield(fh, 'alpha2')
        fh.alpha2.Enable = 'off';
    end
    if isfield(fh, 'minNumEvt2')
        fh.minNumEvt2.Enable = 'off';
    end
    fh.loadCFUButton.Enable = 'off';
    fh.buttonGroup.Enable = 'off';
    fh.buttonGroup.Text = 'Group (Disabled)';
    guidata(fCFU, fh);
end

function closeViewer(fCFU, fOut)
%closeViewer Close the visible viewer and its hidden supporting figure.

    if isgraphics(fOut)
        delete(fOut);
    end
    if isgraphics(fCFU)
        delete(fCFU);
    end
end
