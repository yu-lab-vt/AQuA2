function [cfuRegions, cfuLists, parentIds, memberships, didMerge, changedIndices, outputGroups, diagnostics] = ...
    mergeSimilarCFUs(cfuRegions, cfuLists, parentIds, memberships, dffCurves, parameters, candidateIndices)
%MERGESIMILARCFUS Conservatively merge likely duplicate final CFUs.
%   Candidate pairs must contact after a small spatial dilation, have highly
%   similar zero-lag Pearson correlation and comparable positive DFF AUC.
%   Sibling basins from one hierarchy parent are excluded by default. Valid
%   pairs are merged with complete linkage, preventing chain-style
%   over-merging.

    if nargin < 6 || isempty(parameters)
        parameters = cfu.defaultCFUMergeParameters();
    end
    if nargin < 7 || isempty(candidateIndices)
        candidateIndices = 1:numel(cfuRegions);
    end
    didMerge = false;
    changedIndices = [];
    nCFU = numel(cfuRegions);
    outputGroups = num2cell(1:nCFU);
    diagnostics = emptyDiagnostics();
    if ~parameters.Enable || nCFU < 2
        return;
    end
    candidateMask = false(nCFU, 1);
    candidateMask(candidateIndices) = true;

    edgeMatrix = false(nCFU, nCFU);
    similarityMatrix = -inf(nCFU, nCFU);
    regionMasks = cellfun(@(region) region > 0.1, cfuRegions, ...
        'UniformOutput', false);
    contactAreas = spatialContactAreas(regionMasks, ...
        parameters.SpatialDilationRadius);

    for firstIndex = 1:(nCFU - 1)
        for secondIndex = (firstIndex + 1):nCFU
            if ~candidateMask(firstIndex) && ~candidateMask(secondIndex)
                continue;
            end
            diagnostics.EvaluatedPairs = diagnostics.EvaluatedPairs + 1;
            if parameters.ExcludeSiblingBasins && ...
                    parentIds(firstIndex) == parentIds(secondIndex)
                diagnostics.SiblingExcludedPairs = diagnostics.SiblingExcludedPairs + 1;
                continue;
            end
            contactArea = contactAreas(firstIndex, secondIndex);
            if contactArea < parameters.MinimumOverlapPixels
                diagnostics.SpatialRejectedPairs = diagnostics.SpatialRejectedPairs + 1;
                continue;
            end
            diagnostics.SpatialCandidatePairs = diagnostics.SpatialCandidatePairs + 1;

            [curveCorrelation, aucRatio] = curveFeatures( ...
                dffCurves(firstIndex,:), dffCurves(secondIndex,:));
            passesCorrelation = curveCorrelation >= parameters.MinimumCurveCorrelation;
            passesAUC = aucRatio >= parameters.MinimumPositiveAUCRatio;
            if ~passesCorrelation
                diagnostics.CorrelationRejectedPairs = diagnostics.CorrelationRejectedPairs + 1;
            end
            if ~passesAUC
                diagnostics.AUCRejectedPairs = diagnostics.AUCRejectedPairs + 1;
            end
            if ~passesCorrelation || ~passesAUC
                continue;
            end
            diagnostics.AcceptedEdges = diagnostics.AcceptedEdges + 1;
            edgeMatrix(firstIndex, secondIndex) = true;
            edgeMatrix(secondIndex, firstIndex) = true;
            similarityMatrix(firstIndex, secondIndex) = curveCorrelation;
            similarityMatrix(secondIndex, firstIndex) = curveCorrelation;
        end
    end

    groups = completeLinkageGroups(edgeMatrix, similarityMatrix);
    outputGroups = groups;
    didMerge = any(cellfun(@numel, groups) > 1);
    if ~didMerge
        return;
    end

    [cfuRegions, cfuLists, parentIds, memberships, changedIndices] = mergeGroups( ...
        groups, cfuRegions, cfuLists, parentIds, memberships);
end

function contactAreas = spatialContactAreas(regionMasks, radius)
%SPATIALCONTACTAREAS Count directed dilated-mask contacts in one sparse product.
%   This is equivalent to nnz(imdilate(maskA) & maskB) for every CFU pair,
%   but dilates each mask once instead of once per pair.

    nCFU = numel(regionMasks);
    nPixels = numel(regionMasks{1});
    originalPixels = cell(nCFU, 1);
    dilatedPixels = cell(nCFU, 1);
    for cfuIndex = 1:nCFU
        currentMask = regionMasks{cfuIndex};
        originalPixels{cfuIndex} = find(currentMask);
        kernel = dilationKernelFor(currentMask, radius);
        dilatedPixels{cfuIndex} = find(imdilate(currentMask, kernel));
    end
    originalMatrix = sparsePixelMembership(originalPixels, nPixels);
    dilatedMatrix = sparsePixelMembership(dilatedPixels, nPixels);
    contactAreas = dilatedMatrix' * originalMatrix;
end

function pixelMembership = sparsePixelMembership(pixelLists, nPixels)
    nCFU = numel(pixelLists);
    counts = cellfun(@numel, pixelLists);
    pixelIndices = vertcat(pixelLists{:});
    cfuIndices = repelem((1:nCFU)', counts);
    pixelMembership = sparse(pixelIndices, cfuIndices, 1, nPixels, nCFU);
end

function diagnostics = emptyDiagnostics()
    diagnostics = struct('EvaluatedPairs', 0, 'SiblingExcludedPairs', 0, ...
        'SpatialRejectedPairs', 0, 'SpatialCandidatePairs', 0, ...
        'CorrelationRejectedPairs', 0, 'AUCRejectedPairs', 0, ...
        'AcceptedEdges', 0);
end

function [curveCorrelation, aucRatio] = curveFeatures(firstCurve, secondCurve)
    firstCurve = double(firstCurve(:));
    secondCurve = double(secondCurve(:));
    if numel(firstCurve) ~= numel(secondCurve) || ...
            any(~isfinite(firstCurve)) || any(~isfinite(secondCurve)) || ...
            std(firstCurve) == 0 || std(secondCurve) == 0
        curveCorrelation = -inf;
        aucRatio = 0;
        return;
    end
    correlationMatrix = corrcoef(firstCurve, secondCurve);
    curveCorrelation = correlationMatrix(1,2);
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

function [regionsOut, listsOut, parentsOut, membershipsOut, changedIndices] = mergeGroups( ...
    groups, regionsIn, listsIn, parentsIn, membershipsIn)

    nGroups = numel(groups);
    regionsOut = cell(nGroups, 1);
    listsOut = cell(nGroups, 1);
    parentsOut = zeros(nGroups, 1, 'like', parentsIn);
    membershipsOut = cell(nGroups, 1);
    changedIndices = find(cellfun(@numel, groups) > 1);
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
        spatialValues = cellfun(@(value) value(:), spatialCells, ...
            'UniformOutput', false);
        voxelValues = cellfun(@(value) value(:), voxelCells, ...
            'UniformOutput', false);
        scoreValues = cellfun(@(value) value(:), eventScores, ...
            'UniformOutput', false);
        spatialPixels{eventIndex} = unique(vertcat(spatialValues{:}));
        voxelIndices{eventIndex} = unique(vertcat(voxelValues{:}));
        scores(eventIndex) = max(vertcat(scoreValues{:}));
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
