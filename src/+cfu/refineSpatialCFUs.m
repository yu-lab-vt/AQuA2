function [cfuRegions, cfuLists, parentIds, memberships] = refineSpatialCFUs(candidateLists, evtIhw, weightedIhw, maxCounts, sz, minEvt, candidateParentIds)
%REFINESPATIALCFUS Split CFU candidates while allowing shared events.
%   Spatial components are seeded from a high-confidence core map.  Events
%   may contribute to every component that satisfies absolute and relative
%   weighted-coverage thresholds.  A candidate is split only when at least
%   two resulting components satisfy minEvt; otherwise it is retained.

    finalRegionThreshold = 0.1;
    coreSplitThreshold = 0.2;
    componentAreaRatioThreshold = 0.15;
    absoluteMembershipThreshold = 0.15;
    relativeMembershipThreshold = 0.5;

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

        [weightMap, coreLabels, nComponents] = buildSpatialEvidence( ...
            eventList, evtIhw, weightedIhw, maxCounts, spatialSize, ...
            nSpatialPixels, coreSplitThreshold, componentAreaRatioThreshold);
        strictMask = weightMap > finalRegionThreshold;

        if nComponents < 2
            [regionMap, membership] = preserveCandidate(eventList, weightMap, ...
                strictMask, evtIhw, weightedIhw, maxCounts);
            [cfuRegions, cfuLists, parentIds, memberships] = appendCFU( ...
                cfuRegions, cfuLists, parentIds, memberships, regionMap, ...
                eventList, parentId, membership);
            continue;
        end

        componentLabels = assignStrictPixelsToCores(strictMask, coreLabels, nComponents);
        [branches, branchMemberships] = assignEventsToComponents(eventList, ...
            evtIhw, weightedIhw, maxCounts, componentLabels, nComponents, ...
            absoluteMembershipThreshold, relativeMembershipThreshold);
        validBranches = find(cellfun(@numel, branches) >= minEvt);

        % Be conservative: a failed split must never delete the original
        % candidate CFU.  The original strict (>0.1) region is retained.
        if numel(validBranches) < 2
            [regionMap, membership] = preserveCandidate(eventList, weightMap, ...
                strictMask, evtIhw, weightedIhw, maxCounts);
            [cfuRegions, cfuLists, parentIds, memberships] = appendCFU( ...
                cfuRegions, cfuLists, parentIds, memberships, regionMap, ...
                eventList, parentId, membership);
            continue;
        end

        for componentIndex = validBranches(:)'
            regionMap = weightMap;
            regionMap(componentLabels ~= componentIndex) = 0;
            [cfuRegions, cfuLists, parentIds, memberships] = appendCFU( ...
                cfuRegions, cfuLists, parentIds, memberships, regionMap, ...
                branches{componentIndex}, parentId, branchMemberships{componentIndex});
        end
    end
end

function [weightMap, coreLabels, nComponents] = buildSpatialEvidence( ...
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
    weightMap = reshape(weightVector, spatialSize);

    coreMask = weightMap > coreSplitThreshold;
    if ismatrix(coreMask)
        components = bwconncomp(coreMask, 8);
    else
        components = bwconncomp(coreMask, 26);
    end
    componentAreas = cellfun(@numel, components.PixelIdxList);
    coreLabels = zeros(nSpatialPixels, 1, 'uint16');
    if isempty(componentAreas)
        nComponents = 0;
        return;
    end

    retainedComponents = find(componentAreas > max(componentAreas) * areaRatioThreshold);
    nComponents = numel(retainedComponents);
    for componentIndex = 1:nComponents
        coreLabels(components.PixelIdxList{retainedComponents(componentIndex)}) = componentIndex;
    end
end

function componentLabels = assignStrictPixelsToCores(strictMask, coreLabels, nComponents)
    componentLabels = zeros(size(coreLabels), 'uint16');
    bestDistance = inf(size(strictMask));
    strictPixels = strictMask(:);
    for componentIndex = 1:nComponents
        coreMask = reshape(coreLabels == componentIndex, size(strictMask));
        distanceMap = bwdist(coreMask);
        replace = strictMask & distanceMap < bestDistance;
        bestDistance(replace) = distanceMap(replace);
        currentLabels = reshape(componentLabels, size(strictMask));
        currentLabels(replace) = componentIndex;
        componentLabels = currentLabels(:);
    end
    componentLabels(~strictPixels) = 0;
end

function [branches, memberships] = assignEventsToComponents(eventList, evtIhw, weightedIhw, ...
    maxCounts, componentLabels, nComponents, absoluteThreshold, relativeThreshold)

    branches = cell(nComponents, 1);
    eventIds = cell(nComponents, 1);
    spatialPixels = cell(nComponents, 1);
    scores = cell(nComponents, 1);

    for eventIndex = 1:numel(eventList)
        eventId = eventList(eventIndex);
        eventPixels = evtIhw{eventId};
        eventEvidence = double(weightedIhw{eventId}) * double(maxCounts(eventId));
        totalEvidence = sum(eventEvidence);
        membershipLabels = componentLabels(eventPixels);
        componentScores = zeros(nComponents, 1);
        for componentIndex = 1:nComponents
            componentScores(componentIndex) = ...
                sum(eventEvidence(membershipLabels == componentIndex)) / totalEvidence;
        end

        bestScore = max(componentScores);
        selectedComponents = find(componentScores >= absoluteThreshold & ...
            componentScores >= relativeThreshold * bestScore);
        for componentIndex = selectedComponents(:)'
            branches{componentIndex}(end+1) = eventId;
            eventIds{componentIndex}(end+1) = eventId;
            spatialPixels{componentIndex}{end+1} = ...
                eventPixels(membershipLabels == componentIndex);
            scores{componentIndex}(end+1) = componentScores(componentIndex);
        end
    end

    memberships = cell(nComponents, 1);
    for componentIndex = 1:nComponents
        membership = struct();
        membership.EventID = eventIds{componentIndex};
        membership.SpatialPixels = spatialPixels{componentIndex};
        membership.Score = scores{componentIndex};
        membership.VoxelIndices = cell(1, numel(eventIds{componentIndex}));
        memberships{componentIndex} = membership;
    end
end

function [regionMap, membership] = preserveCandidate(eventList, weightMap, strictMask, ...
    evtIhw, weightedIhw, maxCounts)

    regionMap = weightMap;
    regionMap(~strictMask) = 0;
    spatialPixels = cell(1, numel(eventList));
    scores = zeros(1, numel(eventList));
    for eventIndex = 1:numel(eventList)
        eventId = eventList(eventIndex);
        eventPixels = evtIhw{eventId};
        eventEvidence = double(weightedIhw{eventId}) * double(maxCounts(eventId));
        keep = strictMask(eventPixels);
        spatialPixels{eventIndex} = eventPixels(keep);
        scores(eventIndex) = sum(eventEvidence(keep)) / sum(eventEvidence);
    end
    membership = struct('EventID', eventList, 'SpatialPixels', {spatialPixels}, ...
        'Score', scores, 'VoxelIndices', {cell(1, numel(eventList))});
end

function [cfuRegions, cfuLists, parentIds, memberships] = appendCFU( ...
    cfuRegions, cfuLists, parentIds, memberships, regionMap, eventList, parentId, membership)

    cfuRegions{end+1,1} = regionMap;
    cfuLists{end+1,1} = eventList;
    parentIds(end+1,1) = parentId;
    memberships{end+1,1} = membership;
end
