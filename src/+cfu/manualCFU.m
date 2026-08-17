function manualCFU(action, fCFU, fOut, varargin)
%manualCFU Create, edit, persist, and remove hand-drawn 2-D CFUs.
%
% Manual CFUs are represented by an images.roi.Ellipse and stored in the
% normal CFU information array.  Column 12 is true only for these manual
% records.  The footprint is recalculated from the ellipse after every
% completed move/resize/rotation, so all downstream curve and event data
% stay in sync with what is displayed.

    if nargin < 2 || ~isgraphics(fCFU)
        return;
    end

    switch lower(char(action))
        case 'addpanel'
            if isempty(varargin) || ~isgraphics(varargin{1})
                return;
            end
            addPanel(fCFU, fOut, varargin{1});
        case 'enable'
            setPanelState(fCFU, fOut);
        case 'draw'
            drawManualCFU(fCFU, fOut);
        case 'commit'
            if ~isempty(varargin)
                commitManualCFU(varargin{1}, fCFU, fOut);
            end
        case 'select'
            if ~isempty(varargin)
                selectManualCFU(varargin{1}, fCFU);
            end
        case 'delete'
            deleteSelectedManualCFU(fCFU);
        case 'keypress'
            if ~isempty(varargin)
                handleKeyPress(fCFU, varargin{1});
            end
        case 'restore'
            restoreManualCFUs(fCFU, fOut);
        case 'clear'
            clearManualCFUs(fCFU);
    end
end

function addPanel(fCFU, fOut, panelHost)
    delete(panelHost.Children);
    panelHost.Title = 'Manual CFU';

    grid = uigridlayout(panelHost, [2, 1], ...
        'ColumnWidth', {'1x'}, 'RowHeight', {24, 20}, ...
        'Padding', [6, 3, 6, 3], 'RowSpacing', 3);

    controls = uigridlayout(grid, [1, 4], ...
        'ColumnWidth', {48, 60, 48, '1x'}, 'Padding', [0, 0, 0, 0], ...
        'ColumnSpacing', 4);
    uilabel(controls, 'Text', 'Channel');
    uidropdown(controls, 'Items', {'Ch 1'}, 'ItemsData', 1, 'Value', 1, ...
        'Tag', 'manualCFUChannel', 'Enable', 'off');
    uibutton(controls, 'push', 'Text', 'Draw', 'Tag', 'manualCFUDrawButton', ...
        'Enable', 'off', 'ButtonPushedFcn', ...
        @(~, ~) cfu.manualCFU('draw', fCFU, fOut));
    uibutton(controls, 'push', 'Text', 'Delete selected', ...
        'Tag', 'manualCFUDeleteButton', 'Enable', 'off', 'ButtonPushedFcn', ...
        @(~, ~) cfu.manualCFU('delete', fCFU, []));

    uilabel(grid, 'Text', 'Run CFU detection first.', ...
        'Tag', 'manualCFUStatus', 'FontSize', 10, 'FontColor', [0.35, 0.35, 0.35], ...
        'Tooltip', 'Selected manual CFUs are shown with a thick red border.');
end

function setPanelState(fCFU, fOut)
    fh = guidata(fCFU);
    if ~isstruct(fh) || ~isfield(fh, 'manualCFUDrawButton')
        return;
    end

    [canEdit, message] = canEditManualCFU(fCFU, fOut);
    fh.manualCFUDrawButton.Enable = onOff(canEdit);
    fh.manualCFUDeleteButton.Enable = onOff(canEdit);
    fh.manualCFUChannel.Enable = onOff(canEdit);
    if canEdit
        if fh.opts.singleChannel
            fh.manualCFUChannel.Items = {'Ch 1'};
            fh.manualCFUChannel.ItemsData = 1;
            fh.manualCFUChannel.Value = 1;
        else
            fh.manualCFUChannel.Items = {'Ch 1', 'Ch 2'};
            fh.manualCFUChannel.ItemsData = [1, 2];
            if ~ismember(fh.manualCFUChannel.Value, [1, 2])
                fh.manualCFUChannel.Value = 1;
            end
        end
    end
    fh.manualCFUStatus.Text = message;
    fh.manualCFUStatus.FontColor = [0.35, 0.35, 0.35];
    guidata(fCFU, fh);
end

function drawManualCFU(fCFU, fOut)
    [canEdit, message] = canEditManualCFU(fCFU, fOut);
    if ~canEdit
        showError(fCFU, message);
        return;
    end

    fh = guidata(fCFU);
    channel = fh.manualCFUChannel.Value;
    ax = getChannelAxes(fh, channel);
    if isempty(ax)
        showError(fCFU, 'The selected channel display is unavailable.');
        return;
    end

    try
        roi = drawellipse(ax, 'Color', [1, 0.8, 0], 'FaceAlpha', 0.05, ...
            'LineWidth', 1.5, 'LabelVisible', 'hover', 'Deletable', false, ...
            'DrawingArea', [1, 1, fh.opts.sz(2), fh.opts.sz(1)]);
    catch ME
        showError(fCFU, ME.message);
        return;
    end
    if isempty(roi) || ~isLiveROI(roi) || any(roi.SemiAxes < 0.5)
        if ~isempty(roi) && isLiveROI(roi)
            delete(roi);
        end
        return;
    end

    info = getChannelInfo(fCFU, channel);
    localIndex = size(info, 1) + 1;
    roi.UserData = makeROIData(channel, localIndex);
    roi.Label = sprintf('Manual CFU %d', localIndex);
    attachROIListeners(roi, fCFU, fOut);
    addROIHandle(fCFU, roi);
    commitManualCFU(roi, fCFU, fOut);
end

function commitManualCFU(roi, fCFU, fOut)
    if ~isLiveROI(roi)
        return;
    end
    [canEdit, message] = canEditManualCFU(fCFU, fOut);
    if ~canEdit
        showError(fCFU, message);
        return;
    end

    roiData = roi.UserData;
    if ~isstruct(roiData) || ~isfield(roiData, 'Channel') || ~isfield(roiData, 'Index')
        return;
    end
    channel = roiData.Channel;
    localIndex = roiData.Index;

    try
        [record, shape] = createManualRecord(roi, fOut, channel, localIndex);
        info = ensureInfoColumns(getChannelInfo(fCFU, channel), 12);
        if localIndex < 1 || localIndex > size(info, 1) + 1
            error('cfu:ManualCFUIndex', 'The selected manual CFU no longer has a valid index.');
        end
        info(localIndex, 1:12) = record;
        setChannelInfo(fCFU, channel, info);
        upsertShape(fCFU, shape);
        rebuildCFUMaps(fCFU);

        fh = guidata(fCFU);
        fh = addManualFavourite(fCFU, fh, channel, localIndex);
        fh.manualCFUSelected = [channel, localIndex];
        invalidateAnalysis(fCFU, fh);
        guidata(fCFU, fh);
        cfu.applySpatialBoundary(fCFU);
        cfu.updtCFUTable(fCFU);
        ui.updtCFUint([], [], fCFU, true);
        highlightSelectedROI(fCFU);
        updateStatus(fCFU, sprintf('Manual CFU %d updated and added to Favourite.', localIndex));
    catch ME
        showError(fCFU, ME.message);
    end
end

function selectManualCFU(roi, fCFU)
    if ~isLiveROI(roi)
        return;
    end
    roiData = roi.UserData;
    if isstruct(roiData) && isfield(roiData, 'Channel') && isfield(roiData, 'Index')
        fh = guidata(fCFU);
        fh.manualCFUSelected = [roiData.Channel, roiData.Index];
        guidata(fCFU, fh);
        highlightSelectedROI(fCFU);
        updateStatus(fCFU, sprintf('Manual CFU %d selected (red border). Press Delete to remove it.', ...
            roiData.Index));
    end
end

function handleKeyPress(fCFU, event)
    if ~isstruct(event) && ~isprop(event, 'Key')
        return;
    end
    key = lower(char(event.Key));
    if ismember(key, {'delete', 'backspace'})
        deleteSelectedManualCFU(fCFU);
    end
end

function deleteSelectedManualCFU(fCFU)
    fh = guidata(fCFU);
    if ~isstruct(fh) || ~isfield(fh, 'manualCFUSelected') || ...
            numel(fh.manualCFUSelected) ~= 2
        return;
    end
    channel = fh.manualCFUSelected(1);
    localIndex = fh.manualCFUSelected(2);
    info = getChannelInfo(fCFU, channel);
    if ~iscell(info) || localIndex < 1 || localIndex > size(info, 1) || ...
            size(info, 2) < 12 || ~isequal(info{localIndex, 12}, true)
        return;
    end

    nChannel1 = size(getChannelInfo(fCFU, 1), 1);
    removeROIForRecord(fCFU, channel, localIndex);
    info(localIndex, :) = [];
    if ~isempty(info)
        info(:, 1) = num2cell((1:size(info, 1)).');
    end
    setChannelInfo(fCFU, channel, info);
    renumberManualShapesAndROIs(fCFU, channel, localIndex);

    fh = guidata(fCFU);
    fh.favCFUs = updateFavouritesAfterDelete(fh.favCFUs, channel, localIndex, nChannel1);
    fh.selectCFUs = updateSelectionsAfterDelete(fh.selectCFUs, channel, localIndex);
    fh.manualCFUSelected = [0, 0];
    invalidateAnalysis(fCFU, fh);
    guidata(fCFU, fh);
    rebuildCFUMaps(fCFU);
    cfu.applySpatialBoundary(fCFU);
    cfu.updtCFUTable(fCFU);
    ui.updtCFUint([], [], fCFU, true);
    updateStatus(fCFU, 'Manual CFU deleted.');
end

function restoreManualCFUs(fCFU, fOut)
    clearROIHandles(fCFU);
    shapes = getShapes(fCFU);
    fh = guidata(fCFU);
    if isempty(shapes) || ~isstruct(fh) || ~isfield(fh, 'opts') || fh.opts.sz(3) ~= 1
        addAllManualFavourites(fCFU);
        setPanelState(fCFU, fOut);
        return;
    end
    [canEdit, ~] = canEditManualCFU(fCFU, fOut);
    for k = 1:numel(shapes)
        shape = shapes(k);
        if ~isValidShape(shape) || ~isManualInfoRecord(fCFU, shape.Channel, shape.Index)
            continue;
        end
        ax = getChannelAxes(fh, shape.Channel);
        if isempty(ax)
            continue;
        end
        try
            roi = images.roi.Ellipse(ax, 'Center', shape.Center, ...
                'SemiAxes', shape.SemiAxes, 'RotationAngle', shape.RotationAngle, ...
                'Color', [1, 0.8, 0], 'FaceAlpha', 0.05, 'LineWidth', 1.5, ...
                'Label', sprintf('Manual CFU %d', shape.Index), ...
                'LabelVisible', 'hover', 'Deletable', false, ...
                'InteractionsAllowed', ternary(canEdit, 'all', 'none'));
            roi.UserData = makeROIData(shape.Channel, shape.Index);
            attachROIListeners(roi, fCFU, fOut);
            addROIHandle(fCFU, roi);
        catch ME
            warning('cfu:ManualCFURestoreFailed', '%s', ME.message);
        end
    end
    addAllManualFavourites(fCFU);
    highlightSelectedROI(fCFU);
    setPanelState(fCFU, fOut);
end

function clearManualCFUs(fCFU)
    clearROIHandles(fCFU);
    setappdata(fCFU, 'manualCFUShapes', emptyShapes());
    fh = guidata(fCFU);
    if isstruct(fh)
        fh.manualCFUSelected = [0, 0];
        guidata(fCFU, fh);
    end
end

function [record, shape] = createManualRecord(roi, fOut, channel, localIndex)
    if channel == 1
        dataName = 'datOrg1';
        eventsName = 'evt1';
        featuresName = 'fts1';
    else
        dataName = 'datOrg2';
        eventsName = 'evt2';
        featuresName = 'fts2';
    end
    if ~isappdata(fOut, dataName) || ~isappdata(fOut, eventsName)
        error('cfu:ManualCFUSource', 'Source movie data or detected events are unavailable.');
    end

    data = getappdata(fOut, dataName);
    events = getappdata(fOut, eventsName);
    opts = getappdata(fOut, 'opts');
    [height, width, depth, timePoints] = size(data);
    if depth ~= 1 || numel(opts.sz) < 4 || any([height, width, depth, timePoints] ~= opts.sz(1:4))
        error('cfu:ManualCFUSize', 'Manual ellipse CFUs require the original 2-D source movie.');
    end

    mask = logical(flipud(roi.createMask()));
    if ~isequal(size(mask), [height, width]) || ~any(mask, 'all')
        error('cfu:ManualCFUEmpty', 'The ellipse must contain at least one image pixel.');
    end
    weightMap = double(mask);
    pixels = find(mask);
    [eventIds, eventFrames, eventBounds] = collectOverlappingEvents(events, pixels, ...
        height, width, timePoints);
    timeWindow = false(1, timePoints);
    for k = 1:numel(eventFrames)
        timeWindow(eventFrames{k}) = true;
    end

    dataVector = reshape(double(data), [], timePoints);
    curve = mean(dataVector(pixels, :), 1);
    if channel == 1
        curve = scaleCurve(curve, opts, 1);
    else
        curve = scaleCurve(curve, opts, 2);
    end
    dff = calculateDFF(curve, opts.movAvgWin, opts.cut);
    occurrence = false(1, timePoints);
    peaks = zeros(numel(eventIds), 1);
    features = [];
    if isappdata(fOut, featuresName)
        features = getappdata(fOut, featuresName);
    end
    smoothedCurve = movmean(curve, 2);
    for k = 1:numel(eventIds)
        bounds = eventBounds(k, :);
        rise = cfu.getRisingTime(smoothedCurve, bounds(1), bounds(2), timeWindow, 0.4:0.1:0.6);
        rise = min(max(round(rise), 1), timePoints);
        occurrence(rise) = true;
        peaks(k) = getEventPeak(features, eventIds(k), eventFrames{k}, rise);
    end

    record = cell(1, 12);
    record{1} = localIndex;
    record{2} = eventIds;
    record{3} = weightMap;
    record{4} = occurrence;
    record{5} = curve;
    record{6} = dff;
    record{7} = timeWindow;
    record{8} = false(1, timePoints);
    record{9} = calculateFrequencyStats(peaks, opts.frameRate);
    record{10} = [];
    record{11} = [];
    record{12} = true;

    shape = struct('Version', 1, 'Channel', channel, 'Index', localIndex, ...
        'Center', double(roi.Center), 'SemiAxes', double(roi.SemiAxes), ...
        'RotationAngle', double(roi.RotationAngle));
end

function [eventIds, eventFrames, eventBounds] = collectOverlappingEvents(events, pixels, height, width, timePoints)
    eventIds = zeros(1, 0);
    eventFrames = cell(1, 0);
    eventBounds = zeros(0, 2);
    if ~iscell(events)
        return;
    end
    for eventIndex = 1:numel(events)
        eventPixels = events{eventIndex};
        if isempty(eventPixels)
            continue;
        end
        [rows, columns, ~, frames] = ind2sub([height, width, 1, timePoints], eventPixels);
        spatialPixels = sub2ind([height, width], rows, columns);
        overlapFrames = unique(frames(ismember(spatialPixels, pixels)));
        if isempty(overlapFrames)
            continue;
        end
        eventIds(end + 1) = eventIndex; %#ok<AGROW>
        eventFrames{end + 1} = overlapFrames(:).'; %#ok<AGROW>
        eventBounds(end + 1, :) = [min(frames), max(frames)]; %#ok<AGROW>
    end
end

function rebuildCFUMaps(fCFU)
    fh = guidata(fCFU);
    if ~isstruct(fh) || ~isfield(fh, 'opts')
        return;
    end
    dimensions = fh.opts.sz(1:3);
    fh.cfuMap1 = buildMap(getChannelInfo(fCFU, 1), dimensions);
    if fh.opts.singleChannel
        fh.cfuMap2 = [];
    else
        fh.cfuMap2 = buildMap(getChannelInfo(fCFU, 2), dimensions);
    end
    fh.cfuMapDS1 = buildDownsampledMap(fh.cfuMap1, fh.sldDsXY.Value, dimensions);
    if fh.opts.singleChannel
        fh.cfuMapDS2 = [];
    else
        fh.cfuMapDS2 = buildDownsampledMap(fh.cfuMap2, fh.sldDsXY.Value, dimensions);
    end
    guidata(fCFU, fh);
end

function cfuMap = buildMap(info, dimensions)
    cfuMap = zeros(dimensions, 'uint16');
    if ~iscell(info) || size(info, 2) < 3
        return;
    end
    for k = 1:size(info, 1)
        footprint = info{k, 3};
        if isnumeric(footprint) || islogical(footprint)
            if numel(footprint) == prod(dimensions)
                cfuMap(reshape(footprint, dimensions) > 0.1) = uint16(k);
            end
        end
    end
end

function downsampledMap = buildDownsampledMap(cfuMap, scale, dimensions)
    scale = max(1, round(scale));
    target = se.myResize(zeros(dimensions, 'single'), 1 / scale);
    downsampledMap = zeros(size(target), 'uint16');
    targetDimensions = size(target);
    targetDimensions(end + 1:3) = 1;
    labels = label2idx(cfuMap);
    for k = 1:numel(labels)
        if isempty(labels{k})
            continue;
        end
        [rows, columns, slices] = ind2sub(dimensions, labels{k});
        targetPixels = unique(sub2ind(targetDimensions, ceil(rows / scale), ...
            ceil(columns / scale), slices));
        downsampledMap(targetPixels) = uint16(k);
    end
end

function invalidateAnalysis(fCFU, fh)
    if isappdata(fCFU, 'relation')
        rmappdata(fCFU, 'relation');
    end
    if isappdata(fCFU, 'groupInfo')
        rmappdata(fCFU, 'groupInfo');
    end
    fh.groupShow = 0;
    if isfield(fh, 'pThr'); fh.pThr.Enable = 'off'; end
    if isfield(fh, 'minNumCFU'); fh.minNumCFU.Enable = 'off'; end
    if isfield(fh, 'buttonGroup'); fh.buttonGroup.Enable = 'off'; end
    if isfield(fh, 'groupTable'); fh.groupTable.Data = cell(0, 4); end
end

function attachROIListeners(roi, fCFU, fOut)
    moveListener = addlistener(roi, 'ROIMoved', ...
        @(src, ~) cfu.manualCFU('commit', fCFU, fOut, src));
    clickListener = addlistener(roi, 'ROIClicked', ...
        @(src, ~) cfu.manualCFU('select', fCFU, [], src));
    roiData = roi.UserData;
    roiData.Listeners = {moveListener, clickListener};
    roi.UserData = roiData;
end

function addROIHandle(fCFU, roi)
    fh = guidata(fCFU);
    if ~isfield(fh, 'manualCFUHandles') || ~iscell(fh.manualCFUHandles)
        fh.manualCFUHandles = {};
    end
    fh.manualCFUHandles{end + 1} = roi;
    guidata(fCFU, fh);
end

function removeROIForRecord(fCFU, channel, localIndex)
    fh = guidata(fCFU);
    if ~isfield(fh, 'manualCFUHandles') || ~iscell(fh.manualCFUHandles)
        return;
    end
    keep = true(size(fh.manualCFUHandles));
    for k = 1:numel(fh.manualCFUHandles)
        roi = fh.manualCFUHandles{k};
        if ~isLiveROI(roi)
            keep(k) = false;
            continue;
        end
        roiData = roi.UserData;
        if isstruct(roiData) && isequal([roiData.Channel, roiData.Index], [channel, localIndex])
            delete(roi);
            keep(k) = false;
        end
    end
    fh.manualCFUHandles = fh.manualCFUHandles(keep);
    guidata(fCFU, fh);
end

function clearROIHandles(fCFU)
    fh = guidata(fCFU);
    if ~isstruct(fh) || ~isfield(fh, 'manualCFUHandles') || ~iscell(fh.manualCFUHandles)
        return;
    end
    for k = 1:numel(fh.manualCFUHandles)
        roi = fh.manualCFUHandles{k};
        if isLiveROI(roi)
            delete(roi);
        end
    end
    fh.manualCFUHandles = {};
    guidata(fCFU, fh);
end

function highlightSelectedROI(fCFU)
%highlightSelectedROI Make the currently selected ellipse unambiguous.
    fh = guidata(fCFU);
    if ~isstruct(fh) || ~isfield(fh, 'manualCFUHandles') || ...
            ~iscell(fh.manualCFUHandles) || ~isfield(fh, 'manualCFUSelected')
        return;
    end
    selected = fh.manualCFUSelected;
    for k = 1:numel(fh.manualCFUHandles)
        roi = fh.manualCFUHandles{k};
        if ~isLiveROI(roi)
            continue;
        end
        roiData = roi.UserData;
        isSelected = isstruct(roiData) && numel(selected) == 2 && ...
            isequal([roiData.Channel, roiData.Index], selected);
        if isSelected
            roi.Color = [0.95, 0.1, 0.1];
            roi.LineWidth = 3;
            roi.Selected = true;
        else
            roi.Color = [1, 0.8, 0];
            roi.LineWidth = 1.5;
            roi.Selected = false;
        end
    end
end

function renumberManualShapesAndROIs(fCFU, channel, removedIndex)
    shapes = getShapes(fCFU);
    keep = true(size(shapes));
    for k = 1:numel(shapes)
        if shapes(k).Channel == channel && shapes(k).Index == removedIndex
            keep(k) = false;
        elseif shapes(k).Channel == channel && shapes(k).Index > removedIndex
            shapes(k).Index = shapes(k).Index - 1;
        end
    end
    setappdata(fCFU, 'manualCFUShapes', shapes(keep));

    fh = guidata(fCFU);
    if ~isfield(fh, 'manualCFUHandles') || ~iscell(fh.manualCFUHandles)
        return;
    end
    for k = 1:numel(fh.manualCFUHandles)
        roi = fh.manualCFUHandles{k};
        if ~isLiveROI(roi)
            continue;
        end
        roiData = roi.UserData;
        if isstruct(roiData) && roiData.Channel == channel && roiData.Index > removedIndex
            roiData.Index = roiData.Index - 1;
            roi.UserData = roiData;
            roi.Label = sprintf('Manual CFU %d', roiData.Index);
        end
    end
    guidata(fCFU, fh);
end

function upsertShape(fCFU, shape)
    shapes = getShapes(fCFU);
    isSame = arrayfun(@(s) s.Channel == shape.Channel && s.Index == shape.Index, shapes);
    if any(isSame)
        shapes(find(isSame, 1, 'first')) = shape;
    else
        shapes(end + 1) = shape;
    end
    setappdata(fCFU, 'manualCFUShapes', shapes);
end

function shapes = getShapes(fCFU)
    if isappdata(fCFU, 'manualCFUShapes')
        shapes = getappdata(fCFU, 'manualCFUShapes');
    else
        shapes = emptyShapes();
    end
    if ~isstruct(shapes)
        shapes = emptyShapes();
    end
end

function shapes = emptyShapes()
    shapes = struct('Version', {}, 'Channel', {}, 'Index', {}, 'Center', {}, ...
        'SemiAxes', {}, 'RotationAngle', {});
end

function addAllManualFavourites(fCFU)
    fh = guidata(fCFU);
    if ~isstruct(fh)
        return;
    end
    info1 = getChannelInfo(fCFU, 1);
    info2 = getChannelInfo(fCFU, 2);
    fav = getfieldOr(fh, 'favCFUs', []);
    for channel = 1:2
        if channel == 1
            info = info1;
            offset = 0;
        else
            info = info2;
            offset = size(info1, 1);
        end
        if iscell(info) && size(info, 2) >= 12
            manualRows = find(cellfun(@(value) isequal(value, true), info(:, 12)));
            fav = [fav(:); offset + manualRows(:)];
        end
    end
    fh.favCFUs = unique(fav, 'stable');
    guidata(fCFU, fh);
    cfu.updtCFUTable(fCFU);
end

function fh = addManualFavourite(fCFU, fh, channel, localIndex)
    nChannel1 = size(getChannelInfo(fCFU, 1), 1);
    if channel == 1
        globalIndex = localIndex;
    else
        globalIndex = nChannel1 + localIndex;
    end
    if ~isfield(fh, 'favCFUs') || isempty(fh.favCFUs)
        fh.favCFUs = globalIndex;
    elseif ~ismember(globalIndex, fh.favCFUs)
        fh.favCFUs = [fh.favCFUs(:); globalIndex];
    end
end

function fav = updateFavouritesAfterDelete(fav, channel, localIndex, nChannel1)
    fav = fav(:);
    keep = true(size(fav));
    for k = 1:numel(fav)
        if channel == 1
            if fav(k) == localIndex
                keep(k) = false;
            elseif fav(k) > localIndex && fav(k) <= nChannel1
                fav(k) = fav(k) - 1;
            elseif fav(k) > nChannel1
                fav(k) = fav(k) - 1;
            end
        elseif fav(k) == nChannel1 + localIndex
            keep(k) = false;
        end
    end
    fav = unique(fav(keep), 'stable');
end

function selected = updateSelectionsAfterDelete(selected, channel, localIndex)
    if isempty(selected) || size(selected, 2) ~= 2
        return;
    end
    keep = ~(selected(:, 1) == channel & selected(:, 2) == localIndex);
    selected = selected(keep, :);
    selected(selected(:, 1) == channel & selected(:, 2) > localIndex, 2) = ...
        selected(selected(:, 1) == channel & selected(:, 2) > localIndex, 2) - 1;
end

function [canEdit, message] = canEditManualCFU(fCFU, fOut)
    canEdit = false;
    message = 'Run CFU detection first.';
    fh = guidata(fCFU);
    if ~isstruct(fh) || ~isfield(fh, 'opts') || fh.opts.sz(3) ~= 1
        message = 'Manual ellipse CFUs are available for 2-D data only.';
        return;
    end
    if isempty(getChannelInfo(fCFU, 1))
        return;
    end
    if isempty(fOut) || ~isgraphics(fOut) || ~isappdata(fOut, 'datOrg1') || ...
            ~isappdata(fOut, 'evt1')
        message = 'The source movie and detected events are unavailable in this viewer.';
        return;
    end
    canEdit = true;
    message = 'Draw or edit an ellipse; it is automatically added to Favourite.';
end

function ax = getChannelAxes(fh, channel)
    ax = [];
    if channel == 1
        if isfield(fh, 'mov') && isgraphics(fh.mov)
            ax = fh.mov;
        elseif isfield(fh, 'movL') && isgraphics(fh.movL)
            ax = fh.movL;
        end
    elseif isfield(fh, 'movR') && isgraphics(fh.movR)
        ax = fh.movR;
    end
end

function info = getChannelInfo(fCFU, channel)
    name = sprintf('cfuInfo%d', channel);
    if isappdata(fCFU, name)
        info = getappdata(fCFU, name);
    else
        info = [];
    end
end

function setChannelInfo(fCFU, channel, info)
    setappdata(fCFU, sprintf('cfuInfo%d', channel), info);
end

function info = ensureInfoColumns(info, count)
    if isempty(info)
        info = cell(0, count);
    elseif ~iscell(info)
        error('cfu:ManualCFUInfo', 'The current CFU information is invalid.');
    elseif size(info, 2) < count
        info(:, end + 1:count) = {[]};
    end
end

function tf = isManualInfoRecord(fCFU, channel, localIndex)
    info = getChannelInfo(fCFU, channel);
    tf = iscell(info) && localIndex >= 1 && localIndex <= size(info, 1) && ...
        size(info, 2) >= 12 && isequal(info{localIndex, 12}, true);
end

function data = makeROIData(channel, localIndex)
    data = struct('Channel', channel, 'Index', localIndex, 'Listeners', {{}});
end

function tf = isLiveROI(roi)
    tf = false;
    try
        tf = ~isempty(roi) && isvalid(roi);
    catch
    end
end

function tf = isValidShape(shape)
    tf = isstruct(shape) && isfield(shape, 'Channel') && isfield(shape, 'Index') && ...
        isfield(shape, 'Center') && isfield(shape, 'SemiAxes') && isfield(shape, 'RotationAngle') && ...
        isscalar(shape.Channel) && ismember(shape.Channel, [1, 2]) && ...
        isscalar(shape.Index) && shape.Index >= 1 && ...
        isnumeric(shape.Center) && numel(shape.Center) == 2 && ...
        isnumeric(shape.SemiAxes) && numel(shape.SemiAxes) == 2 && ...
        all(isfinite(shape.Center)) && all(isfinite(shape.SemiAxes)) && ...
        all(shape.SemiAxes > 0) && isfinite(shape.RotationAngle);
end

function curve = scaleCurve(curve, opts, channel)
    minName = sprintf('minValueDat%d', channel);
    maxName = sprintf('maxValueDat%d', channel);
    if isfield(opts, minName) && isfield(opts, maxName)
        curve = curve * (opts.(maxName) - opts.(minName)) + opts.(minName);
    end
end

function peak = getEventPeak(features, eventId, overlapFrames, fallback)
    peak = fallback;
    if isstruct(features) && isfield(features, 'curve') && ...
            isfield(features.curve, 'dffMaxFrame') && ...
            numel(features.curve.dffMaxFrame) >= eventId
        candidate = features.curve.dffMaxFrame(eventId);
        if isfinite(candidate)
            peak = candidate;
            return;
        end
    end
    if ~isempty(overlapFrames)
        peak = overlapFrames(1);
    end
end

function dff = calculateDFF(curve, window, cut)
    datMA = movmean(curve, window);
    timePoints = numel(datMA);
    step = max(1, round(0.5 * cut));
    segments = max(1, ceil(timePoints / step) - 1);
    baseline = zeros(size(curve));
    for k = 1:segments
        startFrame = 1 + (k - 1) * step;
        endFrame = min(timePoints, startFrame + cut);
        [currentMinimum, currentIndex] = min(datMA(startFrame:endFrame));
        currentIndex = currentIndex + startFrame - 1;
        if k == 1
            baseline(1:currentIndex) = currentMinimum;
        elseif currentIndex == previousIndex
            baseline(currentIndex) = currentMinimum;
        else
            baseline(previousIndex:currentIndex) = previousMinimum + ...
                (currentMinimum - previousMinimum) / (currentIndex - previousIndex) * ...
                (0:currentIndex - previousIndex);
        end
        if k == segments
            baseline(currentIndex:end) = currentMinimum;
        end
        previousIndex = currentIndex;
        previousMinimum = currentMinimum;
    end
    sigma = max(1e-4, sqrt(mean((curve(2:end) - curve(1:end - 1)).^2) / 2));
    baseline = baseline - pre.obtainBias(window, cut) * sigma;
    dff = (curve - baseline) ./ (baseline + 1e-4);
end

function stats = calculateFrequencyStats(peaks, secondsPerFrame)
    count = numel(peaks);
    intervals = [];
    mainFrequency = 0;
    method = 'N/A';
    peakFrequency80 = NaN;
    if count >= 2
        intervals = diff(sort(peaks)) * secondsPerFrame;
        intervals = intervals(intervals > 0);
        if ~isempty(intervals)
            if std(intervals) / mean(intervals) > 1
                mainFrequency = median(1 ./ intervals);
                method = 'Med';
            else
                mainFrequency = 1 / mean(intervals);
                method = 'Mean';
            end
            if numel(intervals) >= 5
                peakFrequency80 = prctile(1 ./ intervals, 80);
            end
        end
    end
    stats = struct('count', count, 'mainFreq', mainFrequency, 'method', method, ...
        'peakFreq80', peakFrequency80, 'dt', intervals);
end

function updateStatus(fCFU, text)
    fh = guidata(fCFU);
    if isstruct(fh) && isfield(fh, 'manualCFUStatus') && isgraphics(fh.manualCFUStatus)
        fh.manualCFUStatus.Text = text;
        fh.manualCFUStatus.FontColor = [0, 0.4, 0];
        guidata(fCFU, fh);
    end
end

function showError(fCFU, message)
    if isgraphics(fCFU)
        uialert(fCFU, message, 'Manual CFU', 'Icon', 'error');
    end
end

function value = getfieldOr(structure, name, defaultValue)
    value = defaultValue;
    if isstruct(structure) && isfield(structure, name)
        value = structure.(name);
    end
end

function state = onOff(tf)
    if tf
        state = 'on';
    else
        state = 'off';
    end
end

function value = ternary(condition, trueValue, falseValue)
    if condition
        value = trueValue;
    else
        value = falseValue;
    end
end
