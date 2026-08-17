function restoreSpatialBoundary(fCFU)
%restoreSpatialBoundary Draw a saved 2-D spatial boundary as a dark reference.

    if ~isgraphics(fCFU) || ~isappdata(fCFU, 'spatialBoundary')
        return;
    end
    fh = guidata(fCFU);
    if ~isstruct(fh) || ~isfield(fh, 'opts')
        return;
    end
    opts = fh.opts;
    if ~isstruct(opts) || ~isfield(opts, 'sz') || numel(opts.sz) < 3 || opts.sz(3) ~= 1
        return;
    end

    spatialBoundary = getappdata(fCFU, 'spatialBoundary');
    [xData, yData, isValid] = getBoundaryCoordinates(spatialBoundary, opts.sz(1:3));
    if ~isValid
        warning('cfu:InvalidSpatialBoundary', ...
            'The saved spatial boundary is invalid for the current image and was not displayed.');
        return;
    end

    ax = getSpatialAxes(fCFU);
    if isempty(ax)
        return;
    end

    cfu.clearSpatialBoundaryLine(fCFU);
    oldNextPlot = ax.NextPlot;
    try
        hold(ax, 'on');
        boundaryLine = plot(ax, xData, yData, '--o', 'Color', [0.35, 0.35, 0.35], ...
            'LineWidth', 1.5, 'MarkerFaceColor', [0.35, 0.35, 0.35], ...
            'MarkerSize', 5, 'HitTest', 'off', 'Tag', 'spatialBoundaryReference');
        setappdata(fCFU, 'spatialBoundaryLine', boundaryLine);
    catch ME
        warning('cfu:SpatialBoundaryDisplayFailed', '%s', ME.message);
    end
    if isgraphics(ax)
        ax.NextPlot = oldNextPlot;
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

function [xData, yData, isValid] = getBoundaryCoordinates(boundary, imageSize)
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
        isValid = isnumeric(boundary.ImageSize) && numel(boundary.ImageSize) == 3 && ...
            isequal(double(boundary.ImageSize(:).'), double(imageSize(:).'));
        if ~isValid
            return;
        end
    end
    xData = double(xData(:).');
    yData = double(yData(:).');
end
