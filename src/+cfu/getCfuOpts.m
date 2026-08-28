function cfuOpts = getCfuOpts(fCFU)
    fh = guidata(fCFU);
    cfuOpts.cfuDetect.overlapThr1 = str2double(fh.alpha.Value);
    cfuOpts.cfuDetect.minNumEvt1 = str2double(fh.minNumEvt.Value);
    mergeControlValue = min(max(fh.postMergeCorrelation.Value, 0), 1);
    cfuOpts.cfuDetect.postMergeCorrelationControl = mergeControlValue;
    cfuOpts.cfuDetect.minimumCurveCorrelation = 0.85 + 0.15 * mergeControlValue;
    if isfield(fh, 'alpha2') && isfield(fh, 'minNumEvt2')
        cfuOpts.cfuDetect.overlapThr2 = str2double(fh.alpha2.Value);
        cfuOpts.cfuDetect.minNumEvt2 = str2double(fh.minNumEvt2.Value);
        mergeControlValue2 = min(max(fh.postMergeCorrelation2.Value, 0), 1);
        cfuOpts.cfuDetect.postMergeCorrelationControl2 = mergeControlValue2;
        cfuOpts.cfuDetect.minimumCurveCorrelation2 = 0.85 + 0.15 * mergeControlValue2;
    else
        cfuOpts.cfuDetect.overlapThr2 = cfuOpts.cfuDetect.overlapThr1;
        cfuOpts.cfuDetect.minNumEvt2 = cfuOpts.cfuDetect.minNumEvt1;
        cfuOpts.cfuDetect.postMergeCorrelationControl2 = mergeControlValue;
        cfuOpts.cfuDetect.minimumCurveCorrelation2 = cfuOpts.cfuDetect.minimumCurveCorrelation;
    end
    cfuOpts.cfuAnalysis.maxDist = round(fh.sldWinSz.Value);        % unfixed time window, pick the most significant one
    cfuOpts.cfuAnalysis.shift = abs(round(str2double(fh.shift.Value)));
    cfuOpts.cfuGroup.pValueThr = str2double(fh.pThr.Value);
    cfuOpts.cfuGroup.cfuNumThr = str2double(fh.minNumCFU.Value);
end
