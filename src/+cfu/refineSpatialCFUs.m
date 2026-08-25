function [cfuRegions, cfuLists, parentIds] = refineSpatialCFUs(candidateLists, evtIhw, weightedIhw, maxCounts, sz, minEvt, candidateParentIds)
%REFINESPATIALCFUS Enforce connected CFU regions after event clustering.
%   Candidate event clusters are spatially refined using pairwise footprint
%   IoU. Pairwise similarity changes each event's scalar contribution while
%   the original duration-weighted event maps define the spatial evidence.

    coverageThreshold = 0.5;
    finalRegionThreshold = 0.1;
    coreSplitThreshold = 0.2;
    componentAreaRatioThreshold = 0.1;
    maximumRefinementIterations = 8;

    if nargin < 7 || isempty(candidateParentIds)
        candidateParentIds = (1:numel(candidateLists))';
    end

    if isempty(candidateLists)
        cfuRegions = {};
        cfuLists = {};
        parentIds = zeros(0,1);
        return;
    end

    candidateParentIds = candidateParentIds(:);
    if numel(candidateParentIds) ~= numel(candidateLists)
        error('AQuA2:CFU:InvalidParentIds', ...
            'candidateParentIds must contain one ID for each candidate CFU.');
    end

    spatialSize = sz(1:3);
    nSpatialPixels = prod(spatialSize);
    cfuRegions = {};
    cfuLists = {};
    parentIds = zeros(0,1);

    for candidateIndex = 1:numel(candidateLists)
        parentId = candidateParentIds(candidateIndex);
        initialList = candidateLists{candidateIndex}(:)';
        if numel(initialList) < minEvt
            continue;
        end

        pendingLists = {initialList};
        pendingDepths = 0;
        while ~isempty(pendingLists)
            eventList = pendingLists{1};
            depth = pendingDepths(1);
            pendingLists(1) = [];
            pendingDepths(1) = [];

            [weightMap, componentLabels, nComponents] = buildStrictRegion( ...
                eventList, evtIhw, weightedIhw, maxCounts, spatialSize, nSpatialPixels, ...
                coreSplitThreshold, componentAreaRatioThreshold);
            if nComponents == 0
                continue;
            end

            branches = reassignEvents(eventList, evtIhw, weightedIhw, maxCounts, ...
                componentLabels, nComponents, coverageThreshold);
            branchSizes = cellfun(@numel, branches);
            validBranches = find(branchSizes >= minEvt);
            if isempty(validBranches)
                continue;
            end

            % A stable group has one retained spatial component and all of
            % its events remain assigned to it. It is ready for output.
            if nComponents == 1 && isscalar(validBranches) && ...
                    isequal(sort(branches{validBranches}), sort(eventList))
                cfuRegions{end+1,1} = keepComponentRegion( ...
                    weightMap, componentLabels, 1, finalRegionThreshold); %#ok<AGROW>
                cfuLists{end+1,1} = eventList; %#ok<AGROW>
                parentIds(end+1,1) = parentId; %#ok<AGROW>
                continue;
            end

            % If all events choose one component while other components are
            % unsupported, retain only that component instead of looping.
            if isscalar(validBranches) && ...
                    isequal(sort(branches{validBranches}), sort(eventList))
                onlyComponent = validBranches;
                cfuRegions{end+1,1} = keepComponentRegion( ...
                    weightMap, componentLabels, onlyComponent, finalRegionThreshold); %#ok<AGROW>
                cfuLists{end+1,1} = eventList; %#ok<AGROW>
                parentIds(end+1,1) = parentId; %#ok<AGROW>
                continue;
            end

            if depth >= maximumRefinementIterations
                warning('AQuA2:CFU:SpatialRefinementLimit', ...
                    ['Spatial CFU refinement reached its iteration limit. ', ...
                    'Keeping the latest connected branches.']);
                for branchIndex = validBranches(:)'
                    branchMap = keepComponentRegion( ...
                        weightMap, componentLabels, branchIndex, finalRegionThreshold);
                    cfuRegions{end+1,1} = branchMap; %#ok<AGROW>
                    cfuLists{end+1,1} = branches{branchIndex}; %#ok<AGROW>
                    parentIds(end+1,1) = parentId; %#ok<AGROW>
                end
                continue;
            end

            for branchIndex = validBranches(:)'
                pendingLists{end+1,1} = branches{branchIndex}; %#ok<AGROW>
                pendingDepths(end+1,1) = depth + 1; %#ok<AGROW>
            end
        end
    end
end

function [weightMap, componentLabels, nComponents] = buildStrictRegion( ...
    eventList, evtIhw, weightedIhw, maxCounts, spatialSize, nSpatialPixels, ...
    coreSplitThreshold, areaRatioThreshold)

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

    if spatialSize(3) == 1
        coreMap = reshape(weightVector > coreSplitThreshold, spatialSize(1), spatialSize(2));
        components = bwconncomp(coreMap, 8);
    else
        coreMap = reshape(weightVector > coreSplitThreshold, spatialSize);
        components = bwconncomp(coreMap, 26);
    end

    componentLabels = zeros(nSpatialPixels, 1, 'uint16');
    componentAreas = cellfun(@numel, components.PixelIdxList);
    if isempty(componentAreas)
        nComponents = 0;
        weightMap = reshape(weightVector, spatialSize);
        weightMap(:) = 0;
        return;
    end

    largestArea = max(componentAreas);
    retainedComponents = find(componentAreas > largestArea * areaRatioThreshold);
    nComponents = numel(retainedComponents);
    for componentIndex = 1:nComponents
        componentLabels(components.PixelIdxList{retainedComponents(componentIndex)}) = componentIndex;
    end

    weightMap = reshape(weightVector, spatialSize);
end

function regionMap = keepComponentRegion(weightMap, componentLabels, componentIndex, finalRegionThreshold)
    finalMask = weightMap > finalRegionThreshold;
    if ismatrix(finalMask)
        components = bwconncomp(finalMask, 8);
    else
        components = bwconncomp(finalMask, 26);
    end

    retainedMask = false(size(finalMask));
    corePixels = find(componentLabels == componentIndex);
    for component = 1:components.NumObjects
        currentPixels = components.PixelIdxList{component};
        if any(ismember(currentPixels, corePixels))
            retainedMask(currentPixels) = true;
        end
    end
    regionMap = weightMap;
    regionMap(~retainedMask) = 0;
end

function branches = reassignEvents(eventList, evtIhw, weightedIhw, maxCounts, ...
    componentLabels, nComponents, coverageThreshold)
    branches = cell(nComponents, 1);
    for i = 1:numel(eventList)
        eventId = eventList(i);
        eventPixels = evtIhw{eventId};
        eventEvidence = double(weightedIhw{eventId}) * double(maxCounts(eventId));
        componentMembership = componentLabels(eventPixels);
        coverages = zeros(nComponents, 1);
        for componentIndex = 1:nComponents
            coverages(componentIndex) = sum(eventEvidence(componentMembership == componentIndex)) / ...
                sum(eventEvidence);
        end
        [maximumCoverage, bestComponent] = max(coverages);
        if maximumCoverage >= coverageThreshold
            branches{bestComponent}(end+1) = eventList(i);
        end
    end
end
