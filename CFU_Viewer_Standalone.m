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
    if isfield(loadedData, 'spatialBoundary')
        setappdata(fCFU, 'spatialBoundary', loadedData.spatialBoundary);
    end
    
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

    % The built-in CFU layout reserves its lower-left panel for 3-D tools.
    % Reuse that panel in 2-D so the classification controls never overlap
    % either the image or the dF/F curve while the window is resized.
    createSpatialClassificationPanel(fCFU, H, W, L);

    % Save guidata and refresh
    guidata(fCFU, fh);
    cfu.updtCFUTable(fCFU);
    cfu.updtGrpTable(fCFU, fOut);
    ui.updtCFUint([], [], fCFU, true);
    restoreSpatialBoundary(fCFU, H, W, L);

    % 8. Disable non-runnable functions
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
        if isvalid(fOut)
            delete(fOut);
        end
    catch
        % The hidden parent figure can already have been deleted.
    end
    try
        delete(fCFU);
    catch
        % The CFU figure can already have been deleted by the window manager.
    end
end

function createSpatialClassificationPanel(fCFU, H, W, L)
%createSpatialClassificationPanel Add 2-D classification controls to the left panel.

    if L ~= 1
        return;
    end

    panelHost = findobj(fCFU, 'Type', 'uipanel', 'Tag', 'pSelect');
    if numel(panelHost) ~= 1 || ~isvalid(panelHost)
        warning('CFU_Viewer_Standalone:SpatialPanelUnavailable', ...
            'The spatial-classification panel could not be added to the CFU layout.');
        return;
    end

    delete(panelHost.Children);
    panelHost.Title = 'Spatial Polyline Classification';
    panelHost.Visible = 'on';

    grid = uigridlayout(panelHost, [4, 2], ...
        'ColumnWidth', {130, '1x'}, 'RowHeight', {20, 22, 22, 22}, ...
        'Padding', [10, 8, 10, 8], 'RowSpacing', 5, 'ColumnSpacing', 5);
    instruction = uilabel(grid, 'Text', 'Start at the left edge; right-click to cancel.');
    instruction.Layout.Column = [1, 2];
    uilabel(grid, 'Text', 'Upper class (A) label');
    editA = uieditfield(grid, 'numeric', 'Value', 0);
    uilabel(grid, 'Text', 'Lower class (B) label');
    editB = uieditfield(grid, 'numeric', 'Value', 1);
    button = uibutton(grid, 'push', 'Text', 'Draw boundary and classify', ...
        'ButtonPushedFcn', @(src, ~) drawPolylineAndClassify(src, fCFU, editA, editB, H, W, L));
    button.Layout.Column = [1, 2];
end

function drawPolylineAndClassify(btnSrc, fCFU, editA, editB, H, W, L)
%drawPolylineAndClassify Draw a 2-D boundary and assign every CFU a class.

    fh = guidata(fCFU);
    if isfield(fh, 'mov') && isgraphics(fh.mov)
        ax = fh.mov;
    elseif isfield(fh, 'movL') && isgraphics(fh.movL)
        ax = fh.movL;
    else
        uialert(fCFU, 'The 2-D spatial image axes could not be located.', 'Spatial Classification');
        return;
    end
    if ~isprop(ax, 'XLim') || ~isprop(ax, 'YLim')
        uialert(fCFU, 'Spatial polyline classification supports 2-D images only.', 'Spatial Classification');
        return;
    end

    xLim = ax.XLim;
    yLim = ax.YLim;
    if ~isnumeric(xLim) || ~isnumeric(yLim) || numel(xLim) ~= 2 || numel(yLim) ~= 2 || ...
            any(~isfinite([xLim, yLim])) || xLim(2) <= xLim(1) || yLim(2) <= yLim(1)
        uialert(fCFU, 'The current image coordinate limits are invalid.', 'Spatial Classification');
        return;
    end

    oldButtonDown = fCFU.WindowButtonDownFcn;
    oldButtonMotion = fCFU.WindowButtonMotionFcn;
    oldPointer = fCFU.Pointer;
    oldNextPlot = ax.NextPlot;
    oldTitle = struct('String', ax.Title.String, 'Color', ax.Title.Color, ...
        'FontSize', ax.Title.FontSize, 'FontWeight', ax.Title.FontWeight);
    edgeSnapFraction = 0.02;
    wasCleaned = false;
    xs = [];
    ys = [];
    setStoredSpatialBoundaryLineAppearance(fCFU, 'reference');

    try
        hold(ax, 'on');
        boundaryLine = plot(ax, NaN, NaN, '-o', 'Color', [1, 0.85, 0], ...
            'LineWidth', 2, 'MarkerFaceColor', 'r', 'MarkerSize', 6, ...
            'HitTest', 'off', 'Tag', 'spatialBoundaryCurrent');
        previewLine = plot(ax, NaN, NaN, 'y--', 'LineWidth', 1.5, 'HitTest', 'off');
    catch ME
        ax.NextPlot = oldNextPlot;
        setStoredSpatialBoundaryLineAppearance(fCFU, 'active');
        uialert(fCFU, ME.message, 'Unable to Start Drawing');
        return;
    end

    btnSrc.Enable = 'off';
    btnSrc.Text = 'Drawing...';
    fCFU.Pointer = 'crosshair';
    title(ax, 'Left-click to add points; click near the right edge to finish; right-click to cancel', ...
        'Color', 'r', 'FontSize', 12);
    fCFU.WindowButtonDownFcn = @mouseClickCallback;
    fCFU.WindowButtonMotionFcn = @mouseMoveCallback;

    function mouseClickCallback(src, ~)
        if strcmp(src.SelectionType, 'alt')
            cleanUpDrawing();
            return;
        end
        if ~strcmp(src.SelectionType, 'normal')
            return;
        end

        point = ax.CurrentPoint;
        x = point(1, 1);
        y = point(1, 2);
        if x < xLim(1) || x > xLim(2) || y < yLim(1) || y > yLim(2)
            return;
        end

        xSpan = diff(xLim);
        snapMargin = max(1, edgeSnapFraction * xSpan);
        xDirNormal = strcmpi(ax.XDir, 'normal');
        leftEdge = xLim(1 + ~xDirNormal);
        rightEdge = xLim(2 - ~xDirNormal);
        if isempty(xs)
            x = leftEdge;
        elseif (xDirNormal && x >= xLim(2) - snapMargin) || ...
                (~xDirNormal && x <= xLim(1) + snapMargin)
            x = rightEdge;
        end

        movesRight = isempty(xs) || (xDirNormal && x > xs(end)) || ...
            (~xDirNormal && x < xs(end));
        if ~movesRight
            title(ax, 'The boundary must progress from left to right.', 'Color', 'm', 'FontSize', 12);
            return;
        end

        xs(end + 1) = x;
        ys(end + 1) = y;
        set(boundaryLine, 'XData', xs, 'YData', ys);
        set(previewLine, 'XData', NaN, 'YData', NaN);

        if isequal(x, rightEdge)
            executeClassification();
        else
            title(ax, sprintf('%d point(s) added; continue right and finish near the edge.', numel(xs)), ...
                'Color', 'r', 'FontSize', 11);
        end
    end

    function mouseMoveCallback(~, ~)
        if isempty(xs) || ~isgraphics(previewLine)
            return;
        end
        point = ax.CurrentPoint;
        x = point(1, 1);
        y = point(1, 2);
        if x < xLim(1) || x > xLim(2) || y < yLim(1) || y > yLim(2)
            set(previewLine, 'XData', NaN, 'YData', NaN);
            return;
        end

        snapMargin = max(1, edgeSnapFraction * diff(xLim));
        if (strcmpi(ax.XDir, 'normal') && x >= xLim(2) - snapMargin)
            x = xLim(2);
        elseif strcmpi(ax.XDir, 'reverse') && x <= xLim(1) + snapMargin
            x = xLim(1);
        end
        set(previewLine, 'XData', [xs(end), x], 'YData', [ys(end), y]);
    end

    function cleanUpDrawing(keepNewBoundary)
        if nargin < 1
            keepNewBoundary = false;
        end
        if wasCleaned
            return;
        end
        wasCleaned = true;
        if ~keepNewBoundary && isgraphics(boundaryLine)
            delete(boundaryLine);
        end
        if isgraphics(previewLine)
            delete(previewLine);
        end
        if isgraphics(fCFU)
            fCFU.WindowButtonDownFcn = oldButtonDown;
            fCFU.WindowButtonMotionFcn = oldButtonMotion;
            fCFU.Pointer = oldPointer;
        end
        if isgraphics(ax)
            ax.NextPlot = oldNextPlot;
            title(ax, oldTitle.String, 'Color', oldTitle.Color, ...
                'FontSize', oldTitle.FontSize, 'FontWeight', oldTitle.FontWeight);
        end
        if isgraphics(btnSrc)
            btnSrc.Enable = 'on';
            btnSrc.Text = 'Draw boundary and classify';
        end
        if ~keepNewBoundary
            setStoredSpatialBoundaryLineAppearance(fCFU, 'active');
        end
    end

    function executeClassification()
        try
            valA = editA.Value;
            valB = editB.Value;
            if ~isscalar(valA) || ~isscalar(valB) || ~isfinite(valA) || ~isfinite(valB) || isequal(valA, valB)
                error('CFU_Viewer_Standalone:InvalidClasses', ...
                    'Classes A and B must be distinct finite numeric values.');
            end
            if numel(xs) < 2
                error('CFU_Viewer_Standalone:IncompleteBoundary', ...
                    'Start at the left edge and finish the boundary at the right edge.');
            end

            cfuInfo1 = getappdata(fCFU, 'cfuInfo1');
            if ~iscell(cfuInfo1) || size(cfuInfo1, 2) < 3 || isempty(cfuInfo1)
                error('CFU_Viewer_Standalone:InvalidCFUData', ...
                    'The current session does not contain valid CFU data to classify.');
            end
            nCFU = size(cfuInfo1, 1);
            centres = zeros(nCFU, 2);
            invalidFootprints = false(nCFU, 1);
            for i = 1:nCFU
                [centres(i, :), isValid] = getCFUCentre(cfuInfo1{i, 3}, H, W, L);
                if ~isValid
                    invalidFootprints(i) = true;
                end
            end
            invalidIds = find(invalidFootprints);
            if ~isempty(invalidIds)
                shownIds = sprintf('%d, ', invalidIds(1:min(end, 8)));
                error('CFU_Viewer_Standalone:InvalidFootprint', ...
                    'CFU footprint data are invalid (IDs: %s). No classifications were changed.', ...
                    shownIds(1:end-2));
            end

            [lineX, order] = sort(xs);
            lineY = ys(order);
            extension = max([abs(xLim), W]) + 1e6;
            lineX = [-extension, lineX, extension];
            lineY = [lineY(1), lineY, lineY(end)];
            yLine = interp1(lineX, lineY, centres(:, 1), 'linear');
            if strcmpi(ax.YDir, 'normal')
                isAbove = centres(:, 2) > yLine;
            else
                isAbove = centres(:, 2) < yLine;
            end
            cfuLabels = repmat(valB, nCFU, 1);
            cfuLabels(isAbove) = valA;

            % Match the main CFU GUI: column 10 stores event metadata, and
            % column 11 stores the spatial classification label.
            cfuInfo1(:, 11) = num2cell(cfuLabels);
            spatialBoundary = createSpatialBoundary(xs, ys, valA, valB, [H, W, L]);
            removeStoredSpatialBoundaryLine(fCFU);
            setappdata(fCFU, 'cfuInfo1', cfuInfo1);
            setappdata(fCFU, 'spatialClassLabels', cfuLabels);
            setappdata(fCFU, 'spatialBoundary', spatialBoundary);
            setappdata(fCFU, 'spatialBoundaryLine', boundaryLine);
            cleanUpDrawing(true);
            uialert(fCFU, sprintf(['Spatial polyline classification is complete.\n' ...
                'Upper class (A): %d CFU(s)\nLower class (B): %d CFU(s)\n\n' ...
                'The classifications and boundary were saved with the current CFU results.'], ...
                sum(isAbove), sum(~isAbove)), 'Spatial Classification', 'Icon', 'success');
        catch ME
            cleanUpDrawing();
            uialert(fCFU, ME.message, 'Spatial Classification Failed', 'Icon', 'error');
        end
    end
end

function restoreSpatialBoundary(fCFU, H, W, L)
%restoreSpatialBoundary Draw a saved spatial boundary as a dark reference line.

    if L ~= 1 || ~isappdata(fCFU, 'spatialBoundary')
        return;
    end
    spatialBoundary = getappdata(fCFU, 'spatialBoundary');
    [xData, yData, isValid] = getSpatialBoundaryCoordinates(spatialBoundary, H, W, L);
    if ~isValid
        warning('CFU_Viewer_Standalone:InvalidSpatialBoundary', ...
            'The saved spatial boundary is invalid for the current image and was not displayed.');
        return;
    end

    fh = guidata(fCFU);
    if isfield(fh, 'mov') && isgraphics(fh.mov)
        ax = fh.mov;
    elseif isfield(fh, 'movL') && isgraphics(fh.movL)
        ax = fh.movL;
    else
        return;
    end
    if ~isprop(ax, 'XLim') || ~isprop(ax, 'YLim')
        return;
    end

    removeStoredSpatialBoundaryLine(fCFU);
    oldNextPlot = ax.NextPlot;
    try
        hold(ax, 'on');
        boundaryLine = plot(ax, xData, yData, '--o', 'Color', [0.35, 0.35, 0.35], ...
            'LineWidth', 1.5, 'MarkerFaceColor', [0.35, 0.35, 0.35], ...
            'MarkerSize', 5, 'HitTest', 'off', 'Tag', 'spatialBoundaryReference');
        setappdata(fCFU, 'spatialBoundaryLine', boundaryLine);
    catch ME
        warning('CFU_Viewer_Standalone:SpatialBoundaryDisplayFailed', '%s', ME.message);
    end
    if isgraphics(ax)
        ax.NextPlot = oldNextPlot;
    end
end

function boundary = createSpatialBoundary(xData, yData, classA, classB, imageSize)
%createSpatialBoundary Build the serializable representation of one boundary.

    boundary = struct('Version', 1, 'XData', double(xData(:).'), ...
        'YData', double(yData(:).'), 'ClassA', double(classA), ...
        'ClassB', double(classB), 'ImageSize', double(imageSize(:).'), ...
        'ClassificationColumn', 11);
end

function [xData, yData, isValid] = getSpatialBoundaryCoordinates(boundary, H, W, L)
%getSpatialBoundaryCoordinates Validate a saved boundary for the current image.

    xData = [];
    yData = [];
    isValid = isstruct(boundary) && isscalar(boundary) && ...
        isfield(boundary, 'XData') && isfield(boundary, 'YData');
    if ~isValid
        return;
    end

    xData = boundary.XData;
    yData = boundary.YData;
    isValid = isnumeric(xData) && isnumeric(yData) && isvector(xData) && ...
        isvector(yData) && numel(xData) == numel(yData) && numel(xData) >= 2 && ...
        all(isfinite(xData), 'all') && all(isfinite(yData), 'all');
    if ~isValid
        return;
    end
    if isfield(boundary, 'ImageSize')
        imageSize = boundary.ImageSize;
        isValid = isnumeric(imageSize) && numel(imageSize) == 3 && ...
            isequal(double(imageSize(:).'), double([H, W, L]));
        if ~isValid
            return;
        end
    end
    xData = double(xData(:).');
    yData = double(yData(:).');
end

function setStoredSpatialBoundaryLineAppearance(fCFU, appearance)
%setStoredSpatialBoundaryLineAppearance Switch the saved boundary line style.

    if ~isappdata(fCFU, 'spatialBoundaryLine')
        return;
    end
    boundaryLine = getappdata(fCFU, 'spatialBoundaryLine');
    if ~isgraphics(boundaryLine)
        return;
    end

    if strcmp(appearance, 'reference')
        boundaryLine.Color = [0.35, 0.35, 0.35];
        boundaryLine.LineStyle = '--';
        boundaryLine.MarkerFaceColor = [0.35, 0.35, 0.35];
    else
        boundaryLine.Color = [1, 0.85, 0];
        boundaryLine.LineStyle = '-';
        boundaryLine.MarkerFaceColor = 'r';
    end
end

function removeStoredSpatialBoundaryLine(fCFU)
%removeStoredSpatialBoundaryLine Delete the previous boundary graphic only.

    if ~isappdata(fCFU, 'spatialBoundaryLine')
        return;
    end
    boundaryLine = getappdata(fCFU, 'spatialBoundaryLine');
    if isgraphics(boundaryLine)
        delete(boundaryLine);
    end
    rmappdata(fCFU, 'spatialBoundaryLine');
end

function [centre, isValid] = getCFUCentre(weightMap, H, W, L)
%getCFUCentre Return the display-coordinate centroid of one CFU footprint.

    centre = [NaN, NaN];
    isValid = isnumeric(weightMap) || islogical(weightMap);
    if ~isValid || numel(weightMap) ~= H * W * L
        isValid = false;
        return;
    end
    if issparse(weightMap)
        weightMap = full(weightMap);
    end
    try
        weightMap = reshape(double(weightMap), H, W, L);
    catch
        isValid = false;
        return;
    end

    projection = sum(weightMap, 3);
    projection(~isfinite(projection)) = 0;
    validPixels = projection > 0.1;
    if ~any(validPixels, 'all')
        % A valid but empty footprint belongs to the lower class by convention.
        centre = [NaN, NaN];
        return;
    end
    [rows, columns] = find(validPixels);
    weights = projection(validPixels);
    totalWeight = sum(weights);
    if ~isfinite(totalWeight) || totalWeight <= 0
        isValid = false;
        return;
    end
    centre = [sum(columns .* weights) / totalWeight, ...
        H - sum(rows .* weights) / totalWeight + 1];
end
