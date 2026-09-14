function [cfuRegions, cfuLists, parentIds, memberships, curves, dffCurves, ...
    didMerge, roundsCompleted, diagnostics] = iterativeMergeSimilarCFUs( ...
    cfuRegions, cfuLists, ...
    parentIds, memberships, curves, dffCurves, datVec, movAvgWin, cut, parameters)
%ITERATIVEMERGESIMILARCFUS Merge CFUs until no newly merged CFU gains an edge.
%   The first round evaluates all pairs. Later rounds evaluate only pairs
%   touching a CFU changed in the previous round, and recompute traces only
%   for those changed CFUs. This preserves the result of full iterative
%   merging without repeatedly recalculating unchanged CFU curves.

    if nargin < 10 || isempty(parameters)
        parameters = cfu.defaultCFUMergeParameters();
    end
    didMerge = false;
    roundsCompleted = 0;
    diagnostics = struct('Rounds', {{}}, 'Total', struct());
    candidateIndices = 1:numel(cfuRegions);
    for roundIndex = 1:parameters.MaximumMergeRounds
        notifyProgress(parameters, 'evaluate', roundIndex, numel(cfuRegions));
        [cfuRegions, cfuLists, parentIds, memberships, mergedThisRound, ...
            changedIndices, outputGroups, roundDiagnostics] = cfu.mergeSimilarCFUs( ...
            cfuRegions, cfuLists, ...
            parentIds, memberships, dffCurves, parameters, candidateIndices);
        diagnostics.Rounds{roundIndex} = roundDiagnostics;
        roundsCompleted = roundIndex;
        if ~mergedThisRound
            diagnostics.Total = summarizeDiagnostics(diagnostics.Rounds);
            return;
        end

        didMerge = true;
        sourceIndices = cellfun(@(group) group(1), outputGroups);
        curves = curves(sourceIndices,:);
        dffCurves = dffCurves(sourceIndices,:);
        notifyProgress(parameters, 'recompute', roundIndex, numel(changedIndices));
        [changedCurves, changedDffCurves] = cfu.computeCFUCurves( ...
            cfuRegions(changedIndices), datVec, movAvgWin, cut);
        curves(changedIndices,:) = changedCurves;
        dffCurves(changedIndices,:) = changedDffCurves;
        candidateIndices = changedIndices;
    end
    diagnostics.Total = summarizeDiagnostics(diagnostics.Rounds);
end

function total = summarizeDiagnostics(roundDiagnostics)
    if isempty(roundDiagnostics)
        total = struct();
        return;
    end
    countFields = {'EvaluatedPairs', 'SiblingExcludedPairs', ...
        'SpatialRejectedPairs', 'SpatialCandidatePairs', ...
        'CorrelationRejectedPairs', 'AUCRejectedPairs', 'AcceptedEdges'};
    total = struct();
    for fieldIndex = 1:numel(countFields)
        fieldName = countFields{fieldIndex};
        total.(fieldName) = sum(cellfun(@(roundInfo) roundInfo.(fieldName), ...
            roundDiagnostics));
    end
end

function notifyProgress(parameters, stage, roundIndex, count)
    if isfield(parameters, 'ProgressCallback') && ...
            isa(parameters.ProgressCallback, 'function_handle')
        parameters.ProgressCallback(stage, roundIndex, ...
            parameters.MaximumMergeRounds, count);
    end
end
