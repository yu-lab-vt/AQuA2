function parameters = defaultCFUMergeParameters()
%DEFAULTCFUMERGEPARAMETERS Conservative post-processing merge settings.
%   Edit or override these fields when calling cfu.mergeSimilarCFUs.

    parameters.Enable = true;
    parameters.ExcludeSiblingBasins = true;
    parameters.MinimumOverlapPixels = 1;
    parameters.MinimumContainment = 0.25;
    parameters.MinimumCurveCorrelation = 0.98;
    parameters.MaximumPeakLagFrames = 2;
    parameters.MinimumPeakHeightRatio = 0;
end
