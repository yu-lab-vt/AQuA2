function [dF,opts] = baselineRemoveAndNoiseEstimation(datOrg,opts,evtSpatialMask,ch,ff)
% ----------- Modified by Xuelong Mi, 03/22/2023 -----------
    % valid region, if some part of video never change, no need to check
    % Update: Piece-wise linear function to model the noise
    [~,~,~,T] = size(datOrg);
    
    % smooth the data (memory-efficient version)
    datSmo = datOrg;
    if opts.smoXY>0
        for tt=1:T
            datSmo(:,:,:,tt) = imgaussfilt(datSmo(:,:,:,tt),opts.smoXY);
        end
    end
    
    %% linear estimation of F0
    opts.cut = min(opts.cut,T);
    % remove baseline
    tic;
    [F0] = pre.baselineLinearEstimate(datSmo,opts.cut,opts.movAvgWin);
    toc;
    F0Pro = mean(F0,4);
    
    if exist('ff','var')&&~isempty(ff)
        waitbar(0.75,ff);
    end
    % noise estimation - piece wise linear function to model
    tic;
    [stdMapOrg,stdMapGau,tempVarOrg,correctPars] = pre.noise_estimation_function(F0Pro,datOrg,datSmo,opts.smoXY,evtSpatialMask);
    toc;
    
    % correct bias during noise estimation. Bias does not impact noise
    F0 = F0 - pre.obtainBias(opts.movAvgWin,opts.cut) * repmat(stdMapGau,1,1,1,T);
    dF = datSmo-F0;

    % normalization - zscoreMap
    dF = dF./repmat(stdMapGau,1,1,1,T);
    opts.tempVarOrg = tempVarOrg;
    opts.correctPars = correctPars;
    
    if ch==1
        opts.stdMap1 = stdMapGau;
        opts.stdMapOrg1 = stdMapOrg;
        opts.tempVarOrg1 = tempVarOrg;
        opts.correctPars1 = correctPars;
    else
        opts.stdMap2 = stdMapGau;
        opts.stdMapOrg2 = stdMapOrg;
        opts.tempVarOrg2 = tempVarOrg;
        opts.correctPars2 = correctPars;
    end

    % for visualize
    if ch==1
        opts.maxdF1 = min(100,max(dF(:)));
    else
        opts.maxdF2 = min(100,max(dF(:)));
    end
end

