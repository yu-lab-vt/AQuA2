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

    cfuInfo1 = getappdata(fCFU, 'cfuInfo1');
    if ~iscell(cfuInfo1) || size(cfuInfo1, 2) < 3 || isempty(cfuInfo1)
        return;
    end

    height = fh.opts.sz(1);
    width = fh.opts.sz(2);
    depth = fh.opts.sz(3);
    nCFU = size(cfuInfo1, 1);
    centres = zeros(nCFU, 2);
    invalidFootprints = false(nCFU, 1);
    for cfuIndex = 1:nCFU
        [centres(cfuIndex, :), isValid] = getCFUCentre( ...
            cfuInfo1{cfuIndex, 3}, height, width, depth);
        invalidFootprints(cfuIndex) = ~isValid;
    end
    if any(invalidFootprints)
        warning('cfu:InvalidCFUFootprint', ...
            'Some CFU footprints are invalid, so no boundary-based classifications were changed.');
        return;
    end

    [lineX, order] = sort(xData);
    lineY = yData(order);
    extension = max([abs(lineX), width]) + 1e6;
    lineX = [-extension, lineX, extension];
    lineY = [lineY(1), lineY, lineY(end)];
    yLine = interp1(lineX, lineY, centres(:, 1), 'linear');
    ax = getSpatialAxes(fCFU);
    if isempty(ax) || strcmpi(ax.YDir, 'normal')
        isAbove = centres(:, 2) > yLine;
    else
        isAbove = centres(:, 2) < yLine;
    end

    cfuLabels = repmat(classB, nCFU, 1);
    cfuLabels(isAbove) = classA;
    % Column 10 contains CFU event metadata in the main GUI. Keep it
    % intact and store the spatial class in the next column.
    cfuInfo1(:, 11) = num2cell(cfuLabels);
    setappdata(fCFU, 'cfuInfo1', cfuInfo1);
    setappdata(fCFU, 'spatialClassLabels', cfuLabels);
    didApply = true;
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
