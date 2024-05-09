function cfuOpts = getCfuOpts(fCFU)
    fh = guidata(fCFU);
    cfuOpts.cfuDetect.overlapThr1 = str2double(fh.alpha.Value);
    cfuOpts.cfuDetect.minNumEvt1 = str2double(fh.minNumEvt.Value);
    cfuOpts.cfuDetect.overlapThr2 = str2double(fh.alpha.Value);
    cfuOpts.cfuDetect.minNumEvt2 = str2double(fh.minNumEvt.Value);
    cfuOpts.cfuAnalysis.maxDist = round(fh.sldWinSz.Value);        % unfixed time window, pick the most significant one
    cfuOpts.cfuAnalysis.shift = abs(round(str2double(fh.shift.Value)));
    cfuOpts.cfuGroup.pValueThr = str2double(fh.pThr.Value);
    cfuOpts.cfuGroup.cfuNumThr = str2double(fh.minNumCFU.Value);
end