function parameters = defaultCFUMergeParameters()
%DEFAULTCFUMERGEPARAMETERS Conservative post-processing merge settings.
%   Edit or override these fields when calling cfu.mergeSimilarCFUs.

    parameters.Enable = true;
    parameters.ExcludeSiblingBasins = true;
    parameters.SpatialDilationRadius = 1;
    parameters.MinimumOverlapPixels = 1;
    parameters.MinimumCurveCorrelation = 0.925;
    parameters.MinimumPositiveAUCRatio = 0.5;
    parameters.MaximumMergeRounds = 5;
    parameters.ProgressCallback = [];
end
