function parameters = defaultCFUMergeParameters()
%DEFAULTCFUMERGEPARAMETERS Conservative post-processing merge settings.
%   Edit or override these fields when calling cfu.mergeSimilarCFUs.

    parameters.Enable = true;
    parameters.ExcludeSiblingBasins = true;
    parameters.SpatialDilationRadius = 1;
    parameters.MinimumOverlapPixels = 1;
    parameters.MinimumCrossCorrelation = 0.95;
    parameters.MaximumCrossCorrelationLagFrames = 2;
    parameters.MinimumPositiveAUCRatio = 0.5;
end
