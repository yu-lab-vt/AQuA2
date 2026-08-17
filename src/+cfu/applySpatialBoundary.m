function didApply = applySpatialBoundary(fCFU)
%applySpatialBoundary Classify current CFUs using the saved spatial boundary.

    didApply = false;
    if ~isgraphics(fCFU) || ~isappdata(fCFU, 'spatialBoundary')
        return;
    end
    fh = guidata(fCFU);
    if ~isstruct(fh) || ~isfield(fh, 'opts') || ~isfield(fh.opts, 'sz') || ...
            numel(fh.opts.sz) < 3 || fh.opts.sz(3) ~= 1
        return;
    end

    boundary = getappdata(fCFU, 'spatialBoundary');
    [xData, yData, classA, classB, isValid] = getBoundaryData(boundary, fh.opts.sz(1:3));
    if ~isValid
        warning('cfu:InvalidSpatialBoundary', ...
            'The saved spatial boundary is invalid, so the current CFUs were not reclassified.');
        return;
    end

    height = fh.opts.sz(1);
    width = fh.opts.sz(2);
    depth = fh.opts.sz(3);
    ax = getSpatialAxes(fCFU);
    isYNormal = isempty(ax) || strcmpi(ax.YDir, 'normal');

    cfuInfo1 = getappdata(fCFU, 'cfuInfo1');
    [cfuInfo1, cfuLabels, isValid] = classifyCFUs(cfuInfo1, xData, yData, ...
        classA, classB, height, width, depth, isYNormal);
    if ~isValid
        warning('cfu:InvalidCFUFootprint', ...
            'Some channel 1 CFU footprints are invalid, so no boundary-based classifications were changed.');
        return;
    end
    setappdata(fCFU, 'cfuInfo1', cfuInfo1);
    setappdata(fCFU, 'spatialClassLabels', cfuLabels);

    % Apply the same saved line to channel 2 when present.  This is needed
    % for manually drawn Ch2 CFUs and does not alter the existing Ch1 API.
    if isappdata(fCFU, 'cfuInfo2')
        cfuInfo2 = getappdata(fCFU, 'cfuInfo2');
        if iscell(cfuInfo2) && ~isempty(cfuInfo2)
            [cfuInfo2, cfuLabels2, isValid2] = classifyCFUs(cfuInfo2, xData, yData, ...
                classA, classB, height, width, depth, isYNormal);
            if isValid2
                setappdata(fCFU, 'cfuInfo2', cfuInfo2);
                setappdata(fCFU, 'spatialClassLabels2', cfuLabels2);
            else
                warning('cfu:InvalidCFUFootprint', ...
                    'Some channel 2 CFU footprints are invalid, so channel 2 classifications were not changed.');
            end
        end
    end
    didApply = true;
end

function [cfuInfo, cfuLabels, isValid] = classifyCFUs(cfuInfo, xData, yData, ...
        classA, classB, height, width, depth, isYNormal)
    cfuLabels = [];
    isValid = iscell(cfuInfo) && size(cfuInfo, 2) >= 3 && ~isempty(cfuInfo);
    if ~isValid
        return;
    end
    nCFU = size(cfuInfo, 1);
    centres = zeros(nCFU, 2);
    for cfuIndex = 1:nCFU
        [centres(cfuIndex, :), isFootprintValid] = getCFUCentre( ...
            cfuInfo{cfuIndex, 3}, height, width, depth);
        if ~isFootprintValid
            isValid = false;
            return;
        end
    end

    [lineX, order] = sort(xData);
    lineY = yData(order);
    extension = max([abs(lineX), width]) + 1e6;
    lineX = [-extension, lineX, extension];
    lineY = [lineY(1), lineY, lineY(end)];
    yLine = interp1(lineX, lineY, centres(:, 1), 'linear');
    isAbove = centres(:, 2) > yLine;
    if ~isYNormal
        isAbove = centres(:, 2) < yLine;
    end

    cfuLabels = repmat(classB, nCFU, 1);
    cfuLabels(isAbove) = classA;
    % Column 10 contains gray-event metadata, so the spatial class lives
    % in column 11 and the manual-CFU flag remains in column 12.
    cfuInfo(:, 11) = num2cell(cfuLabels);
end

function [xData, yData, classA, classB, isValid] = getBoundaryData(boundary, imageSize)
    xData = [];
    yData = [];
    classA = NaN;
    classB = NaN;
    isValid = isstruct(boundary) && isscalar(boundary) && ...
        isfield(boundary, 'XData') && isfield(boundary, 'YData') && ...
        isfield(boundary, 'ClassA') && isfield(boundary, 'ClassB');
    if ~isValid
        return;
    end

    xData = boundary.XData;
    yData = boundary.YData;
    classA = boundary.ClassA;
    classB = boundary.ClassB;
    isValid = isnumeric(xData) && isnumeric(yData) && isvector(xData) && ...
        isvector(yData) && numel(xData) == numel(yData) && numel(xData) >= 2 && ...
        all(isfinite(xData), 'all') && all(isfinite(yData), 'all') && ...
        isnumeric(classA) && isnumeric(classB) && isscalar(classA) && isscalar(classB) && ...
        isfinite(classA) && isfinite(classB) && ~isequal(classA, classB);
    if ~isValid
        return;
    end
    if isfield(boundary, 'ImageSize')
        isValid = isnumeric(boundary.ImageSize) && numel(boundary.ImageSize) == 3 && ...
            isequal(double(boundary.ImageSize(:).'), double(imageSize(:).'));
        if ~isValid
            return;
        end
    end
    xData = double(xData(:).');
    yData = double(yData(:).');
    classA = double(classA);
    classB = double(classB);
end

function ax = getSpatialAxes(fCFU)
    ax = [];
    fh = guidata(fCFU);
    if isfield(fh, 'mov') && isgraphics(fh.mov) && isprop(fh.mov, 'YDir')
        ax = fh.mov;
    elseif isfield(fh, 'movL') && isgraphics(fh.movL) && isprop(fh.movL, 'YDir')
        ax = fh.movL;
    end
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
