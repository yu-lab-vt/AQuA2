function [cfuRegions, cfuLists, parentIds, memberships, didMerge] = ...
    mergeSimilarCFUs(cfuRegions, cfuLists, parentIds, memberships, dffCurves, parameters)
%MERGESIMILARCFUS Conservatively merge likely duplicate final CFUs.
%   Candidate pairs must overlap directly, have sufficient containment,
%   nearly identical DFF curves, and closely aligned peak frames.  Sibling
%   basins from one hierarchy parent are excluded by default.  Valid pairs
%   are merged with complete linkage, preventing chain-style over-merging.

    if nargin < 6 || isempty(parameters)
        parameters = cfu.defaultCFUMergeParameters();
    end
    didMerge = false;
    nCFU = numel(cfuRegions);
    if ~parameters.Enable || nCFU < 2
        return;
    end

    edgeMatrix = false(nCFU, nCFU);
    similarityMatrix = -inf(nCFU, nCFU);
    regionMasks = cellfun(@(region) region > 0.1, cfuRegions, ...
        'UniformOutput', false);
    regionAreas = cellfun(@nnz, regionMasks);

    for firstIndex = 1:(nCFU - 1)
        for secondIndex = (firstIndex + 1):nCFU
            if parameters.ExcludeSiblingBasins && ...
                    parentIds(firstIndex) == parentIds(secondIndex)
                continue;
            end
            intersectionArea = nnz(regionMasks{firstIndex} & regionMasks{secondIndex});
            containment = intersectionArea / max(min(regionAreas(firstIndex), ...
                regionAreas(secondIndex)), 1);
            if intersectionArea < parameters.MinimumOverlapPixels || ...
                    containment < parameters.MinimumContainment
                continue;
            end

            [curveCorrelation, peakLag, peakHeightRatio] = curveFeatures( ...
                dffCurves(firstIndex,:), dffCurves(secondIndex,:));
            if curveCorrelation < parameters.MinimumCurveCorrelation || ...
                    peakLag > parameters.MaximumPeakLagFrames || ...
                    peakHeightRatio < parameters.MinimumPeakHeightRatio
                continue;
            end
            edgeMatrix(firstIndex, secondIndex) = true;
            edgeMatrix(secondIndex, firstIndex) = true;
            similarityMatrix(firstIndex, secondIndex) = curveCorrelation;
            similarityMatrix(secondIndex, firstIndex) = curveCorrelation;
        end
    end

    groups = completeLinkageGroups(edgeMatrix, similarityMatrix);
    didMerge = any(cellfun(@numel, groups) > 1);
    if ~didMerge
        return;
    end

    [cfuRegions, cfuLists, parentIds, memberships] = mergeGroups( ...
        groups, cfuRegions, cfuLists, parentIds, memberships);
end

function [curveCorrelation, peakLag, peakHeightRatio] = curveFeatures(firstCurve, secondCurve)
    firstCurve = double(firstCurve(:));
    secondCurve = double(secondCurve(:));
    if numel(firstCurve) ~= numel(secondCurve) || ...
            any(~isfinite(firstCurve)) || any(~isfinite(secondCurve)) || ...
            std(firstCurve) == 0 || std(secondCurve) == 0
        curveCorrelation = -inf;
        peakLag = inf;
        peakHeightRatio = 0;
        return;
    end
    correlationMatrix = corrcoef(firstCurve, secondCurve);
    curveCorrelation = correlationMatrix(1,2);
    [firstPeak, firstPeakFrame] = max(firstCurve);
    [secondPeak, secondPeakFrame] = max(secondCurve);
    peakLag = abs(firstPeakFrame - secondPeakFrame);
    peakHeightRatio = min(abs(firstPeak), abs(secondPeak)) / ...
        max([abs(firstPeak), abs(secondPeak), eps]);
end

function groups = completeLinkageGroups(edgeMatrix, similarityMatrix)
    groups = num2cell(1:size(edgeMatrix,1));
    while true
        bestScore = -inf;
        bestPair = [0 0];
        for firstGroup = 1:(numel(groups) - 1)
            for secondGroup = (firstGroup + 1):numel(groups)
                crossEdges = edgeMatrix(groups{firstGroup}, groups{secondGroup});
                if ~all(crossEdges(:))
                    continue;
                end
                crossSimilarity = similarityMatrix(groups{firstGroup}, groups{secondGroup});
                candidateScore = mean(crossSimilarity(:));
                if candidateScore > bestScore
                    bestScore = candidateScore;
                    bestPair = [firstGroup secondGroup];
                end
            end
        end
        if bestPair(1) == 0
            return;
        end
        groups{bestPair(1)} = [groups{bestPair(1)} groups{bestPair(2)}];
        groups(bestPair(2)) = [];
    end
end

function [regionsOut, listsOut, parentsOut, membershipsOut] = mergeGroups( ...
    groups, regionsIn, listsIn, parentsIn, membershipsIn)

    nGroups = numel(groups);
    regionsOut = cell(nGroups, 1);
    listsOut = cell(nGroups, 1);
    parentsOut = zeros(nGroups, 1, 'like', parentsIn);
    membershipsOut = cell(nGroups, 1);
    for groupIndex = 1:nGroups
        memberIndices = groups{groupIndex};
        region = zeros(size(regionsIn{memberIndices(1)}), 'like', regionsIn{memberIndices(1)});
        for memberIndex = memberIndices
            region = max(region, regionsIn{memberIndex});
        end
        regionsOut{groupIndex} = region;
        listsOut{groupIndex} = unique([listsIn{memberIndices}], 'stable');
        parentsOut(groupIndex) = parentsIn(memberIndices(1));
        membershipsOut{groupIndex} = mergeMemberships(membershipsIn(memberIndices), ...
            region, memberIndices, parentsIn(memberIndices));
    end
end

function membership = mergeMemberships(groupMemberships, region, sourceCFUs, sourceParents)
    eventIdCells = cellfun(@(current) current.EventID, groupMemberships, ...
        'UniformOutput', false);
    eventIds = unique([eventIdCells{:}], 'stable');
    spatialPixels = cell(1, numel(eventIds));
    voxelIndices = cell(1, numel(eventIds));
    scores = zeros(1, numel(eventIds));
    for eventIndex = 1:numel(eventIds)
        eventId = eventIds(eventIndex);
        eventSpatialPixels = cell(1, numel(groupMemberships));
        eventVoxelIndices = cell(1, numel(groupMemberships));
        eventScores = cell(1, numel(groupMemberships));
        for membershipIndex = 1:numel(groupMemberships)
            current = groupMemberships{membershipIndex};
            matches = find(current.EventID == eventId);
            eventSpatialPixels{membershipIndex} = current.SpatialPixels(matches);
            eventVoxelIndices{membershipIndex} = current.VoxelIndices(matches);
            eventScores{membershipIndex} = current.Score(matches);
        end
        spatialCells = [eventSpatialPixels{:}];
        voxelCells = [eventVoxelIndices{:}];
        spatialPixels{eventIndex} = unique([spatialCells{:}]);
        voxelIndices{eventIndex} = unique([voxelCells{:}]);
        scores(eventIndex) = max([eventScores{:}]);
    end

    membership = struct('EventID', eventIds, 'SpatialPixels', {spatialPixels}, ...
        'Score', scores, 'VoxelIndices', {voxelIndices});
    [supportPixels, supportWeights] = mergeSupportMaps(groupMemberships);
    membership.SupportPixels = supportPixels;
    membership.SupportWeights = supportWeights;
    membership.PrimaryPixels = find(region > 0.1);
    membership.SpatialSize = size(region);
    membership.MergedFromCFUs = sourceCFUs(:)';
    membership.MergedParentIDs = unique(sourceParents(:)', 'stable');
end

function [supportPixels, supportWeights] = mergeSupportMaps(groupMemberships)
    supportPixelCells = cellfun(@(current) current.SupportPixels(:), ...
        groupMemberships, 'UniformOutput', false);
    supportWeightCells = cellfun(@(current) current.SupportWeights(:), ...
        groupMemberships, 'UniformOutput', false);
    allPixels = vertcat(supportPixelCells{:});
    allWeights = vertcat(supportWeightCells{:});
    [supportPixels, ~, locations] = unique(allPixels);
    supportWeights = accumarray(locations, allWeights, [], @max);
end
