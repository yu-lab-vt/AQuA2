function [seLst,evtLst2,seLstInfoLabel,majorityEvt2,opts,sdLst,mergingInfo,ccRegions] = seDetection(dF,datOrg,arLst,opts,ff)
% ----------- Xuelong Mi, 03/22/2023 -----------
% make it into 3D version
    [H,W,L,T] = size(dF);
    
    %% setting
%     opts.TPatch = 20;               % naturally it's to avoid too long-duration signal
                                    % downsample the curve to 20 time points
    tic;
    %% Test Split By my methods from active region
    %% Top-Down seed detection
    % is there any advantage that when checking seeds, calculate the score
    % for each pixel then combine them together? -- Since each individual
    % pixel in seed has different time windows. Consider the potential
    % propagation, we cannot use the average curve for seed detection.

    disp('Seed detection');
%     [Map] = se.seedDetect(dF,datOrg,arLst,opts,ff);
    [Map,arLst] = se.seedDetect2_DS_accelerate(dF,datOrg,arLst,opts,ff); 
    toc;

    %% one region, multiple seeds within the same time window
%     se.growSpa(Map,arLst,datOrg);

    %% segmentation according to seed
    tic;
    disp('Watershed grow');
%     [evtLst,sdLst,ccRegions] = se.segmentation_MSF2(Map,arLst,dF,dFOrg,opts,ff);
    [evtLst,sdLst,ccRegions] = se.markerControlledSplitting_Ac(Map,arLst,dF,opts,ff);
    clear Map;
    toc;

    %% remove empty
    szEvt = cellfun(@numel,evtLst);
    sdLst = sdLst(szEvt>0);
    evtLst = evtLst(szEvt>0);

    %% select major part
    tic;
    disp('Majority')
    majorityEvt0 = se.getMajority_Ac(sdLst,evtLst,dF,opts);
    toc;

    % addtional -----------------------
    
    if(~isfield(opts,'overlap'))
        opts.overlap = 0.5;
    end 

    % In temporal dimension, two peaks are closely adjacent, they may be in one seed, i.e., one event.
    % may need further refine it.
    if (opts.needRefine)
        disp('Temporally splitting curve according to gap');
        tic;
        [evtLst2,majorityEvt2,sdLst] = se.splitEvt_Ac(dF,datOrg,evtLst,sdLst,majorityEvt0,opts);
        toc;
        clear dFSmoVec;
    else
        evtLst2 = evtLst;majorityEvt2 = majorityEvt0;
    end
    
    %% Grow spatially
    if (opts.needGrow)
        disp('Further grow regions with similar temporal pattern');
        tic;
        [evtLst2,ccRegions] = se.growWatershedResultSpatial(evtLst2,majorityEvt2,dF,opts);
        toc;
    end

    % according to curve, refine
    disp('Refining');
    tic;
    [sdLst,evtLst2,majorityEvt2] = se.majorCurveFilter2(datOrg,dF,sdLst,evtLst2,majorityEvt2,opts);
    toc;

%     disp('Refining Region');
%     tic;
%     [evtLst2] = se.refineShape(datOrg,evtLst2);
%     toc;


    %% Merge to super event
    tic;
    disp('Merging signals with similar temporal patterns');
    [mergingInfo,majorityEvt2] = se.createMergingInfo(evtLst2,majorityEvt2,ccRegions,size(dF),opts);
    [seLst,seLstInfoLabel,mergingInfo] = se.mergingSEbyInfo_UpdateSpa(evtLst2,majorityEvt2,mergingInfo,size(dF),ccRegions,opts);
    toc;

    if exist('ff','var')&&~isempty(ff)
        waitbar(1,ff);
    end


end