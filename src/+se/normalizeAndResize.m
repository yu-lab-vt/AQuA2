function [datResize] = normalizeAndResize(datOrg,opts)
    [H,W,L,~] = size(datOrg);
    scaleRatios = opts.scaleRatios;
    datResize = cell(numel(scaleRatios),1);
     
    %% Rescl dFOrg
    for i = 1:numel(scaleRatios)
        scaleRatio = scaleRatios(i);
        datDS = se.myResize(datOrg,1/scaleRatio);
        
        % consider the possible noise correlation, need to re-estimate noise
        curVarMap = mean((datDS(:,:,:,2:end) - datDS(:,:,:,1:end-1)).^2,4,'omitnan')/2;

        % correct noise due to truncation
        var1 = se.myResize(opts.tempVarOrg,1/scaleRatio); 
        var2 = se.myResize(opts.tempVarOrg*2./opts.correctPars,1/scaleRatio); 

        curStdMap = sqrt(curVarMap.*var2./var1);
        datDS = datDS./curStdMap;   % since it is only used in seed detection, and seed detection only check single pixel's score. Not need to fitting again.
        
        datResize{i} = datDS;     % ==> zscoreMap scaling.
    end
end