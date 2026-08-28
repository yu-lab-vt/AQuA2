function [curves, dffCurves] = computeCFUCurves(cfuRegions, datVec, movAvgWin, cut)
%COMPUTECFUCURVES Compute weighted raw and DFF traces from final CFU maps.

    nCFU = numel(cfuRegions);
    nFrames = size(datVec, 2);
    curves = zeros(nCFU, nFrames);
    dffCurves = zeros(nCFU, nFrames);
    for cfuIndex = 1:nCFU
        weightMap = cfuRegions{cfuIndex}(:);
        pixels = find(weightMap > 0);
        curves(cfuIndex,:) = weightMap(pixels)' * double(datVec(pixels,:)) / ...
            sum(weightMap(pixels));
        dffCurves(cfuIndex,:) = calculateDFF(curves(cfuIndex,:), movAvgWin, cut);
    end
end

function dff = calculateDFF(curve, window, cut)
    curveMean = movmean(curve, window);
    nFrames = numel(curveMean);
    step = round(0.5 * cut);
    nSegments = max(1, ceil(nFrames / step) - 1);
    baseline = zeros(size(curve));
    for segmentIndex = 1:nSegments
        firstFrame = 1 + (segmentIndex - 1) * step;
        lastFrame = min(nFrames, firstFrame + cut);
        [currentMinimum, currentFrame] = min(curveMean(firstFrame:lastFrame));
        currentFrame = currentFrame + firstFrame - 1;
        if segmentIndex == 1
            baseline(1:currentFrame) = currentMinimum;
        else
            baseline(previousFrame:currentFrame) = previousMinimum + ...
                (currentMinimum - previousMinimum) / (currentFrame - previousFrame) * ...
                (0:(currentFrame - previousFrame));
        end
        if segmentIndex == nSegments
            baseline(currentFrame:end) = currentMinimum;
        end
        previousFrame = currentFrame;
        previousMinimum = currentMinimum;
    end
    noiseSigma = max(1e-4, sqrt(mean((curve(2:end) - curve(1:end-1)).^2) / 2));
    baseline = baseline - pre.obtainBias(window, cut) * noiseSigma;
    dff = (curve - baseline) ./ (baseline + 1e-4);
end
