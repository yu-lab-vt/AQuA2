function [cfuRegions, cfuLists, parentIds, memberships, didMerge] = ...
    mergeSimilarCFUs(cfuRegions, cfuLists, parentIds, memberships, dffCurves, parameters)
%MERGESIMILARCFUS Conservatively merge likely duplicate final CFUs.
%   Candidate pairs must contact after a small spatial dilation, have highly
%   similar normalized cross-correlation, comparable positive DFF AUC, and
%   a small cross-correlation lag. Sibling basins from one hierarchy parent
%   are excluded by default. Valid pairs are merged with complete linkage,
%   preventing chain-style over-merging.

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

    for firstIndex = 1:(nCFU - 1)
        for secondIndex = (firstIndex + 1):nCFU
            if parameters.ExcludeSiblingBasins && ...
                    parentIds(firstIndex) == parentIds(secondIndex)
                continue;
            end
            dilationKernel = dilationKernelFor(regionMasks{firstIndex}, ...
                parameters.SpatialDilationRadius);
            contactArea = nnz(imdilate(regionMasks{firstIndex}, dilationKernel) & ...
                regionMasks{secondIndex});
            if contactArea < parameters.MinimumOverlapPixels
                continue;
            end

            [crossCorrelation, crossCorrelationLag, aucRatio] = curveFeatures( ...
                dffCurves(firstIndex,:), dffCurves(secondIndex,:));
            if crossCorrelation < parameters.MinimumCrossCorrelation || ...
                    crossCorrelationLag > parameters.MaximumCrossCorrelationLagFrames || ...
                    aucRatio < parameters.MinimumPositiveAUCRatio
                continue;
            end
            edgeMatrix(firstIndex, secondIndex) = true;
            edgeMatrix(secondIndex, firstIndex) = true;
            similarityMatrix(firstIndex, secondIndex) = crossCorrelation;
            similarityMatrix(secondIndex, firstIndex) = crossCorrelation;
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

function [crossCorrelation, crossCorrelationLag, aucRatio] = curveFeatures(firstCurve, secondCurve)
    firstCurve = double(firstCurve(:));
    secondCurve = double(secondCurve(:));
    if numel(firstCurve) ~= numel(secondCurve) || ...
            any(~isfinite(firstCurve)) || any(~isfinite(secondCurve)) || ...
            std(firstCurve) == 0 || std(secondCurve) == 0
        crossCorrelation = -inf;
        crossCorrelationLag = inf;
        aucRatio = 0;
        return;
    end
    firstCentered = firstCurve - mean(firstCurve);
    secondCentered = secondCurve - mean(secondCurve);
    [crossCorrelationValues, lags] = xcorr(firstCentered, secondCentered, 'coeff');
    [crossCorrelation, bestIndex] = max(crossCorrelationValues);
    crossCorrelationLag = abs(lags(bestIndex));
    firstAUC = trapz(max(firstCurve, 0));
    secondAUC = trapz(max(secondCurve, 0));
    aucRatio = min(firstAUC, secondAUC) / max([firstAUC, secondAUC, eps]);
end

function kernel = dilationKernelFor(regionMask, radius)
    if radius <= 0
        if ismatrix(regionMask) || size(regionMask, 3) == 1
            kernel = true(1, 1);
        else
            kernel = true(1, 1, 1);
        end
        return;
    end
    if ismatrix(regionMask) || size(regionMask, 3) == 1
        kernel = true(2 * radius + 1, 2 * radius + 1);
    else
        kernel = true(2 * radius + 1, 2 * radius + 1, 2 * radius + 1);
    end
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
