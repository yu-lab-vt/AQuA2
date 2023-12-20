function [noise] = avgDatNoiseEst(curve,ihw,opts)
% Xuelong Mi 02/11/2023
% get noise of one curve
% assume the noise is average of ihw pixels
    % mean((curve(2:end) - curve(1:end-1)).^2)/2  \sigma^2 calculated
    % directly from curve
    if size(ihw,2)~=1
        ihw = ihw';
    end
    varBefCorr = mean((curve(2:end) - curve(1:end-1)).^2)/2;

    wVector = ones(numel(ihw),1);
    var1 = opts.tempVarOrg(ihw);    % variance in raw data
    var2 = var1*2./opts.correctPars(ihw); % corrected variance in raw data. correctPars starting from 2

    varAfterCorrect = varBefCorr*(wVector'*var2)/(wVector'*var1);
    noise = sqrt(varAfterCorrect);
end