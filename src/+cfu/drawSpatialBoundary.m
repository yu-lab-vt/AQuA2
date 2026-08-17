function drawSpatialBoundary(button, fCFU, editA, editB)
%drawSpatialBoundary Draw a 2-D boundary and classify CFUs relative to it.

    fh = guidata(fCFU);
    if ~isstruct(fh) || ~isfield(fh, 'opts')
        uialert(fCFU, 'The current CFU display configuration is unavailable.', ...
            'Spatial Classification');
        return;
    end
    opts = fh.opts;
    if ~isstruct(opts) || ~isfield(opts, 'sz') || numel(opts.sz) < 3 || opts.sz(3) ~= 1
        uialert(fCFU, 'Spatial polyline classification supports 2-D images only.', ...
            'Spatial Classification');
        return;
    end
    imageSize = opts.sz(1:3);
    ax = getSpatialAxes(fCFU);
    if isempty(ax)
        uialert(fCFU, 'The 2-D spatial image axes could not be located.', ...
            'Spatial Classification');
        return;
    end

    xLim = ax.XLim;
    yLim = ax.YLim;
    if ~isnumeric(xLim) || ~isnumeric(yLim) || numel(xLim) ~= 2 || numel(yLim) ~= 2 || ...
            any(~isfinite([xLim, yLim])) || xLim(2) <= xLim(1) || yLim(2) <= yLim(1)
        uialert(fCFU, 'The current image coordinate limits are invalid.', ...
            'Spatial Classification');
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
    xPoints = [];
    yPoints = [];
    setStoredBoundaryAppearance(fCFU, 'reference');

    try
        hold(ax, 'on');
        boundaryLine = plot(ax, NaN, NaN, '-o', 'Color', [1, 0.85, 0], ...
            'LineWidth', 2, 'MarkerFaceColor', 'r', 'MarkerSize', 6, ...
            'HitTest', 'off', 'Tag', 'spatialBoundaryCurrent');
        previewLine = plot(ax, NaN, NaN, 'y--', 'LineWidth', 1.5, 'HitTest', 'off');
    catch ME
        ax.NextPlot = oldNextPlot;
        setStoredBoundaryAppearance(fCFU, 'active');
        uialert(fCFU, ME.message, 'Unable to Start Drawing');
        return;
    end

    button.Enable = 'off';
    button.Text = 'Drawing...';
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

        snapMargin = max(1, edgeSnapFraction * diff(xLim));
        xDirNormal = strcmpi(ax.XDir, 'normal');
        leftEdge = xLim(1 + ~xDirNormal);
        rightEdge = xLim(2 - ~xDirNormal);
        if isempty(xPoints)
            x = leftEdge;
        elseif (xDirNormal && x >= xLim(2) - snapMargin) || ...
                (~xDirNormal && x <= xLim(1) + snapMargin)
            x = rightEdge;
        end

        movesRight = isempty(xPoints) || (xDirNormal && x > xPoints(end)) || ...
            (~xDirNormal && x < xPoints(end));
        if ~movesRight
            title(ax, 'The boundary must progress from left to right.', 'Color', 'm', 'FontSize', 12);
            return;
        end

        xPoints(end + 1) = x;
        yPoints(end + 1) = y;
        set(boundaryLine, 'XData', xPoints, 'YData', yPoints);
        set(previewLine, 'XData', NaN, 'YData', NaN);
        if isequal(x, rightEdge)
            executeClassification();
        else
            title(ax, sprintf('%d point(s) added; continue right and finish near the edge.', ...
                numel(xPoints)), 'Color', 'r', 'FontSize', 11);
        end
    end

    function mouseMoveCallback(~, ~)
        if isempty(xPoints) || ~isgraphics(previewLine)
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
        if strcmpi(ax.XDir, 'normal') && x >= xLim(2) - snapMargin
            x = xLim(2);
        elseif strcmpi(ax.XDir, 'reverse') && x <= xLim(1) + snapMargin
            x = xLim(1);
        end
        set(previewLine, 'XData', [xPoints(end), x], 'YData', [yPoints(end), y]);
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
        if isgraphics(button)
            button.Enable = 'on';
            button.Text = 'Draw boundary and classify';
        end
        if ~keepNewBoundary
            setStoredBoundaryAppearance(fCFU, 'active');
        end
    end

    function executeClassification()
        try
            classA = editA.Value;
            classB = editB.Value;
            if ~isscalar(classA) || ~isscalar(classB) || ~isfinite(classA) || ...
                    ~isfinite(classB) || isequal(classA, classB)
                error('cfu:InvalidClasses', 'Classes A and B must be distinct finite numeric values.');
            end
            if numel(xPoints) < 2
                error('cfu:IncompleteBoundary', ...
                    'Start at the left edge and finish the boundary at the right edge.');
            end

            cfuInfo1 = getappdata(fCFU, 'cfuInfo1');
            if ~iscell(cfuInfo1) || size(cfuInfo1, 2) < 3 || isempty(cfuInfo1)
                error('cfu:InvalidCFUData', ...
                    'The current session does not contain valid CFU data to classify.');
            end
            nCFU = size(cfuInfo1, 1);
            centres = zeros(nCFU, 2);
            invalidFootprints = false(nCFU, 1);
            for cfuIndex = 1:nCFU
                [centres(cfuIndex, :), isValid] = getCFUCentre( ...
                    cfuInfo1{cfuIndex, 3}, imageSize(1), imageSize(2), imageSize(3));
                invalidFootprints(cfuIndex) = ~isValid;
            end
            invalidIds = find(invalidFootprints);
            if ~isempty(invalidIds)
                shownIds = sprintf('%d, ', invalidIds(1:min(end, 8)));
                error('cfu:InvalidFootprint', ...
                    'CFU footprint data are invalid (IDs: %s). No classifications were changed.', ...
                    shownIds(1:end-2));
            end

            [lineX, order] = sort(xPoints);
            lineY = yPoints(order);
            extension = max([abs(xLim), imageSize(2)]) + 1e6;
            lineX = [-extension, lineX, extension];
            lineY = [lineY(1), lineY, lineY(end)];
            yLine = interp1(lineX, lineY, centres(:, 1), 'linear');
            if strcmpi(ax.YDir, 'normal')
                isAbove = centres(:, 2) > yLine;
            else
                isAbove = centres(:, 2) < yLine;
            end
            cfuLabels = repmat(classB, nCFU, 1);
            cfuLabels(isAbove) = classA;

            % Column 10 contains CFU event metadata in the main GUI. Keep
            % it intact and store the spatial class in the next column.
            cfuInfo1(:, 11) = num2cell(cfuLabels);
            spatialBoundary = createSpatialBoundary(xPoints, yPoints, classA, classB, imageSize);
            cfu.clearSpatialBoundaryLine(fCFU);
            setappdata(fCFU, 'cfuInfo1', cfuInfo1);
            setappdata(fCFU, 'spatialClassLabels', cfuLabels);
            setappdata(fCFU, 'spatialBoundary', spatialBoundary);
            setappdata(fCFU, 'spatialBoundaryLine', boundaryLine);
            % Reuse the central classifier so a second channel, including
            % manual Ch2 CFUs, receives the same boundary label as Ch1.
            cfu.applySpatialBoundary(fCFU);
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

function ax = getSpatialAxes(fCFU)
    ax = [];
    fh = guidata(fCFU);
    if isfield(fh, 'mov') && isgraphics(fh.mov) && isprop(fh.mov, 'XLim')
        ax = fh.mov;
    elseif isfield(fh, 'movL') && isgraphics(fh.movL) && isprop(fh.movL, 'XLim')
        ax = fh.movL;
    end
end

function setStoredBoundaryAppearance(fCFU, appearance)
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

function boundary = createSpatialBoundary(xData, yData, classA, classB, imageSize)
    boundary = struct('Version', 1, 'XData', double(xData(:).'), ...
        'YData', double(yData(:).'), 'ClassA', double(classA), ...
        'ClassB', double(classB), 'ImageSize', double(imageSize(:).'), ...
        'ClassificationColumn', 11);
end

function [centre, isValid] = getCFUCentre(weightMap, height, width, depth)
    centre = [NaN, NaN];
    isValid = (isnumeric(weightMap) || islogical(weightMap)) && ...
        numel(weightMap) == height * width * depth;
    if ~isValid
        return;
    end
    if issparse(weightMap)
        weightMap = full(weightMap);
    end
    try
        weightMap = reshape(double(weightMap), height, width, depth);
    catch
        isValid = false;
        return;
    end
    projection = sum(weightMap, 3);
    projection(~isfinite(projection)) = 0;
    validPixels = projection > 0.1;
    if ~any(validPixels, 'all')
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
        height - sum(rows .* weights) / totalWeight + 1];
end
