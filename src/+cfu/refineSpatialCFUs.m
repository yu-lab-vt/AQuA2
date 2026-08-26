function [cfuRegions, cfuLists, parentIds, memberships] = refineSpatialCFUs(candidateLists, evtIhw, weightedIhw, maxCounts, sz, minEvt, candidateParentIds)
%REFINESPATIALCFUS Refine hierarchical CFUs with spatial basins.
%   A hierarchy-derived candidate first produces a continuous SupportMap.
%   Prominent spatial peaks in that map seed a watershed partition.  Each
%   accepted basin is a possible CFU, while events are associated by their
%   local basin coverage and may belong to more than one final CFU.
%
%   cfuRegions contains PrimaryRegion maps for legacy callers and display.
%   The corresponding membership structure retains a sparse SupportMap,
%   so display topology is intentionally independent of event evidence.

    parameters = spatialParameters();

    if nargin < 7 || isempty(candidateParentIds)
        candidateParentIds = (1:numel(candidateLists))';
    end
    if numel(candidateParentIds) ~= numel(candidateLists)
        error('AQuA2:CFU:InvalidParentIds', ...
            'candidateParentIds must contain one ID for each candidate CFU.');
    end

    spatialSize = sz(1:3);
    nSpatialPixels = prod(spatialSize);
    cfuRegions = {};
    cfuLists = {};
    parentIds = zeros(0,1);
    memberships = {};

    for candidateIndex = 1:numel(candidateLists)
        eventList = candidateLists{candidateIndex}(:)';
        parentId = candidateParentIds(candidateIndex);
        if numel(eventList) < minEvt
            continue;
        end

        [weightMap, supportMask, primarySupportMask, basinLabels, nBasins] = ...
            buildSpatialEvidence(eventList, evtIhw, weightedIhw, maxCounts, ...
            spatialSize, nSpatialPixels, parameters);

        if nBasins < 2
            [regionMap, membership] = preserveCandidate(eventList, weightMap, ...
                supportMask, primarySupportMask, evtIhw, weightedIhw, maxCounts);
            [cfuRegions, cfuLists, parentIds, memberships] = appendCFU( ...
                cfuRegions, cfuLists, parentIds, memberships, regionMap, ...
                eventList, parentId, membership);
            continue;
        end

        [branches, branchMemberships] = assignEventsToBasins(eventList, ...
            evtIhw, basinLabels, nBasins, parameters);
        validBranches = find(~cellfun(@isempty, branches));

        % Basin topology, rather than the number of unique events, decides
        % whether to split.  A broad event can legitimately support several
        % basins and therefore occur in several branch lists.
        if numel(validBranches) < 2
            [regionMap, membership] = preserveCandidate(eventList, weightMap, ...
                supportMask, primarySupportMask, evtIhw, weightedIhw, maxCounts);
            [cfuRegions, cfuLists, parentIds, memberships] = appendCFU( ...
                cfuRegions, cfuLists, parentIds, memberships, regionMap, ...
                eventList, parentId, membership);
            continue;
        end

        for basinIndex = validBranches(:)'
            primaryMask = basinLabels == basinIndex;
            regionMap = weightMap;
            regionMap(~primaryMask) = 0;
            branchMemberships{basinIndex} = addSpatialMaps( ...
                branchMemberships{basinIndex}, weightMap, supportMask, primaryMask);
            [cfuRegions, cfuLists, parentIds, memberships] = appendCFU( ...
                cfuRegions, cfuLists, parentIds, memberships, regionMap, ...
                branches{basinIndex}, parentId, branchMemberships{basinIndex});
        end
    end
end

function parameters = spatialParameters()
    parameters.finalRegionThreshold = 0.1;
    parameters.minimumComponentAreaRatio = 0.15;
    parameters.gaussianSigma = 1;
    parameters.peakProminence = 0.12;
    parameters.minimumPeakHeight = 0.3;
    parameters.minimumSaddleDrop = 0.2;
    parameters.minimumBasinCoverage = 0.5;
    parameters.relativeBasinCoverage = 0.75;
end

function [weightMap, supportMask, primarySupportMask, basinLabels, nBasins] = ...
    buildSpatialEvidence(eventList, evtIhw, weightedIhw, maxCounts, spatialSize, ...
    nSpatialPixels, parameters)

    nEvents = numel(eventList);
    iou = eye(nEvents);
    for i = 1:nEvents
        pixelsI = evtIhw{eventList(i)};
        for j = (i + 1):nEvents
            pixelsJ = evtIhw{eventList(j)};
            intersectionPixels = numel(intersect(pixelsI, pixelsJ));
            unionPixels = numel(pixelsI) + numel(pixelsJ) - intersectionPixels;
            iou(i,j) = intersectionPixels / max(unionPixels, 1);
            iou(j,i) = iou(i,j);
        end
    end

    nodeWeights = sum(iou, 2);
    nodeWeights = nodeWeights / max(nodeWeights);
    weightVector = zeros(nSpatialPixels, 1, 'single');
    for i = 1:nEvents
        eventId = eventList(i);
        eventEvidence = single(weightedIhw{eventId}) * single(maxCounts(eventId));
        weightVector(evtIhw{eventId}) = weightVector(evtIhw{eventId}) + ...
            single(nodeWeights(i)) * eventEvidence;
    end
    maximumWeight = max(weightVector);
    if maximumWeight > 0
        weightVector = weightVector / maximumWeight;
    end
    weightMap = reshape(weightVector, spatialSize);
    supportMask = weightMap > parameters.finalRegionThreshold;
    primarySupportMask = removeSmallSupportComponents( ...
        supportMask, parameters.minimumComponentAreaRatio);

    [basinLabels, nBasins] = extractSpatialBasins(weightMap, ...
        primarySupportMask, parameters);
end

function primarySupportMask = removeSmallSupportComponents(supportMask, areaRatio)
    components = bwconncomp(supportMask, connectivityFor(supportMask));
    areas = cellfun(@numel, components.PixelIdxList);
    primarySupportMask = false(size(supportMask));
    if isempty(areas)
        return;
    end
    retained = find(areas >= max(areas) * areaRatio);
    for componentIndex = retained(:)'
        primarySupportMask(components.PixelIdxList{componentIndex}) = true;
    end
end

function [basinLabels, nBasins] = extractSpatialBasins(weightMap, primarySupportMask, parameters)
    basinLabels = zeros(numel(weightMap), 1, 'uint16');
    nBasins = 0;
    if ~any(primarySupportMask(:))
        return;
    end

    connectivity = connectivityFor(weightMap);
    smoothedMap = imgaussfilt(weightMap, parameters.gaussianSigma);
    maximumValue = max(smoothedMap(:));
    if maximumValue <= 0
        return;
    end
    smoothedMap = smoothedMap / maximumValue;
    smoothedMap(~primarySupportMask) = 0;

    seedMask = imextendedmax(smoothedMap, parameters.peakProminence, connectivity);
    seedMask = seedMask & primarySupportMask & ...
        smoothedMap >= parameters.minimumPeakHeight;
    if ~any(seedMask(:))
        return;
    end

    imposedMap = imimposemin(-smoothedMap, seedMask | ~primarySupportMask, connectivity);
    watershedLabels = watershed(imposedMap, connectivity);
    [initialLabels, peaks] = labelsContainingSeeds(watershedLabels, seedMask, smoothedMap);
    if isempty(peaks)
        return;
    end

    initialLabels = mergeShallowBasins(initialLabels, smoothedMap, peaks, ...
        primarySupportMask, parameters.minimumSaddleDrop);
    basinLabels = assignSupportPixelsToBasins(primarySupportMask, initialLabels, connectivity);
    nBasins = double(max(basinLabels(:)));
end

function [labels, peaks] = labelsContainingSeeds(watershedLabels, seedMask, smoothedMap)
    seedLabels = unique(watershedLabels(seedMask));
    seedLabels(seedLabels == 0) = [];
    labels = zeros(size(watershedLabels), 'uint16');
    peaks = zeros(numel(seedLabels), 1);
    for seedIndex = 1:numel(seedLabels)
        basinMask = watershedLabels == seedLabels(seedIndex);
        labels(basinMask) = seedIndex;
        peaks(seedIndex) = max(smoothedMap(basinMask));
    end
end

function labels = mergeShallowBasins(labels, smoothedMap, peaks, supportMask, saddleDrop)
    nBasins = numel(peaks);
    parent = 1:nBasins;
    ridgeMask = labels == 0 & supportMask;
    neighborhood = true(neighborhoodSizeFor(labels));
    for firstBasin = 1:(nBasins - 1)
        firstBorder = imdilate(labels == firstBasin, neighborhood);
        for secondBasin = (firstBasin + 1):nBasins
            saddlePixels = ridgeMask & firstBorder & ...
                imdilate(labels == secondBasin, neighborhood);
            if ~any(saddlePixels(:))
                continue;
            end
            saddleHeight = max(smoothedMap(saddlePixels));
            if saddleHeight > (1 - saddleDrop) * min(peaks(firstBasin), peaks(secondBasin))
                parent = joinSets(parent, firstBasin, secondBasin);
            end
        end
    end

    roots = zeros(nBasins, 1);
    for basinIndex = 1:nBasins
        roots(basinIndex) = findSet(parent, basinIndex);
    end
    uniqueRoots = unique(roots, 'stable');
    mergedLabels = zeros(size(labels), 'uint16');
    for mergedIndex = 1:numel(uniqueRoots)
        sourceLabels = find(roots == uniqueRoots(mergedIndex));
        mergedLabels(ismember(labels, sourceLabels)) = mergedIndex;
    end
    labels = mergedLabels;
end

function labels = assignSupportPixelsToBasins(supportMask, initialLabels, connectivity)
    labels = zeros(size(initialLabels), 'uint16');
    components = bwconncomp(supportMask, connectivity);
    for componentIndex = 1:components.NumObjects
        componentPixels = components.PixelIdxList{componentIndex};
        componentMask = false(size(supportMask));
        componentMask(componentPixels) = true;
        componentBasins = unique(initialLabels(componentPixels));
        componentBasins(componentBasins == 0) = [];
        bestDistance = inf(size(supportMask));
        for basinIndex = componentBasins(:)'
            basinMask = initialLabels == basinIndex;
            distanceMap = bwdist(basinMask);
            update = componentMask & distanceMap < bestDistance;
            labels(update) = basinIndex;
            bestDistance(update) = distanceMap(update);
        end
    end
end

function parent = joinSets(parent, firstIndex, secondIndex)
    firstRoot = findSet(parent, firstIndex);
    secondRoot = findSet(parent, secondIndex);
    if firstRoot ~= secondRoot
        parent(secondRoot) = firstRoot;
    end
end

function root = findSet(parent, index)
    root = index;
    while parent(root) ~= root
        root = parent(root);
    end
end

function [branches, memberships] = assignEventsToBasins(eventList, evtIhw, basinLabels, ...
    nBasins, parameters)

    branches = cell(nBasins, 1);
    eventIds = cell(nBasins, 1);
    spatialPixels = cell(nBasins, 1);
    scores = cell(nBasins, 1);
    basinAreas = accumarray(double(basinLabels(basinLabels > 0)), 1, [nBasins, 1]);

    for eventIndex = 1:numel(eventList)
        eventId = eventList(eventIndex);
        eventPixels = evtIhw{eventId};
        eventBasinLabels = basinLabels(eventPixels);
        basinHit = zeros(nBasins, 1);
        for basinIndex = 1:nBasins
            basinHit(basinIndex) = sum(eventBasinLabels == basinIndex) / ...
                max(basinAreas(basinIndex), 1);
        end
        bestHit = max(basinHit);
        selectedBasins = find(basinHit >= parameters.minimumBasinCoverage & ...
            basinHit >= parameters.relativeBasinCoverage * bestHit);
        for basinIndex = selectedBasins(:)'
            branches{basinIndex}(end+1) = eventId;
            eventIds{basinIndex}(end+1) = eventId;
            spatialPixels{basinIndex}{end+1} = ...
                eventPixels(eventBasinLabels == basinIndex);
            scores{basinIndex}(end+1) = basinHit(basinIndex);
        end
    end

    memberships = cell(nBasins, 1);
    for basinIndex = 1:nBasins
        membership = struct('EventID', eventIds{basinIndex}, ...
            'Score', scores{basinIndex}, ...
            'VoxelIndices', {cell(1, numel(eventIds{basinIndex}))});
        membership.SpatialPixels = spatialPixels{basinIndex};
        memberships{basinIndex} = membership;
    end
end

function [regionMap, membership] = preserveCandidate(eventList, weightMap, supportMask, ...
    primaryMask, evtIhw, weightedIhw, maxCounts)

    regionMap = weightMap;
    regionMap(~primaryMask) = 0;
    spatialPixels = cell(1, numel(eventList));
    scores = zeros(1, numel(eventList));
    for eventIndex = 1:numel(eventList)
        eventId = eventList(eventIndex);
        eventPixels = evtIhw{eventId};
        eventEvidence = double(weightedIhw{eventId}) * double(maxCounts(eventId));
        keep = primaryMask(eventPixels);
        spatialPixels{eventIndex} = eventPixels(keep);
        scores(eventIndex) = sum(eventEvidence(keep)) / max(sum(eventEvidence), eps);
    end
    membership = struct('EventID', eventList, 'SpatialPixels', {spatialPixels}, ...
        'Score', scores, 'VoxelIndices', {cell(1, numel(eventList))});
    membership = addSpatialMaps(membership, weightMap, supportMask, primaryMask);
end

function membership = addSpatialMaps(membership, weightMap, supportMask, primaryMask)
    membership.SupportPixels = find(supportMask);
    membership.SupportWeights = weightMap(supportMask);
    membership.PrimaryPixels = find(primaryMask);
    membership.SpatialSize = size(weightMap);
end

function connectivity = connectivityFor(array)
    if ismatrix(array) || size(array, 3) == 1
        connectivity = 8;
    else
        connectivity = 26;
    end
end

function neighborhoodSize = neighborhoodSizeFor(array)
    if ismatrix(array) || size(array, 3) == 1
        neighborhoodSize = [3 3];
    else
        neighborhoodSize = [3 3 3];
    end
end

function [cfuRegions, cfuLists, parentIds, memberships] = appendCFU( ...
    cfuRegions, cfuLists, parentIds, memberships, regionMap, eventList, parentId, membership)

    cfuRegions{end+1,1} = regionMap;
    cfuLists{end+1,1} = eventList;
    parentIds(end+1,1) = parentId;
    memberships{end+1,1} = membership;
end
