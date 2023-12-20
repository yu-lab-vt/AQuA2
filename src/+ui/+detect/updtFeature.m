function updtFeature(~, ~, f)
    % updtFeature update network features after user draw regions
    % regions are all in x,y coordinate, where y need to be flipped for matrix manipulation

    fprintf('Updating basic, network, region and landmark features\n')
    %% load data
    ov = getappdata(f, 'ov');
    opts = getappdata(f, 'opts');
    evtLst1 = getappdata(f, 'evt1');
    evtLst2 = getappdata(f, 'evt2');
    evtGloLst1 = getappdata(f, 'gloEvt1');
    evtGloLst2 = getappdata(f, 'gloEvt2');
    sz = opts.sz;

    %% basic features
    gg = waitbar(0, 'Updating basic features ...');
    fprintf('Updating basic features (Channel 1) ...\n')
    datOrg1 = getappdata(f, 'datOrg1');
    opts.stdMapOrg = opts.stdMapOrg1;
    opts.maxValueDat = opts.maxValueDat1;
    opts.minValueDat = opts.minValueDat1;
    opts.tempVarOrg = opts.tempVarOrg1;
    opts.correctPars = opts.correctPars1;
    [ftsLstE1, dffMat1, dMat1,dffAlignedMat1] = fea.getFeaturesTop(datOrg1, evtLst1, opts, gg);
    ftsLstE1.channel = 1;
    setappdata(f, 'dffMat1', dffMat1);
    setappdata(f, 'dMat1', dMat1);
    setappdata(f, 'dffAlignedMat1', dffAlignedMat1);
    setappdata(f,'fts1',ftsLstE1);

    if ~isempty(evtGloLst1)
        [ftsLstGloE1, dffMatGlo1, dMatGlo1,dffAlignedMatGlo1] = fea.getFeaturesTop(datOrg1, evtGloLst1, opts, gg);
        ftsLstGloE1.channel = 1;
        setappdata(f, 'dffMatGlo1', dffMatGlo1);
        setappdata(f, 'dMatGlo1', dMatGlo1);
        setappdata(f, 'dffAlignedMatGlo1', dffAlignedMatGlo1);
        setappdata(f, 'ftsGlo1',ftsLstGloE1);
    end

    if(~opts.singleChannel)
        datOrg2 = getappdata(f, 'datOrg2');
        fprintf('Updating basic features (Channel 2) ...\n')
        opts.stdMapOrg = opts.stdMapOrg2;
        opts.maxValueDat = opts.maxValueDat2;
        opts.minValueDat = opts.minValueDat2;
        opts.tempVarOrg = opts.tempVarOrg2;
        opts.correctPars = opts.correctPars2;
        [ftsLstE2, dffMat2, dMat2,dffAlignedMat2] = fea.getFeaturesTop(datOrg2, evtLst2, opts, gg);
        ftsLstE2.channel = 2;
        setappdata(f, 'dffMat2', dffMat2);
        setappdata(f, 'dMat2', dMat2);
        setappdata(f, 'dffAlignedMat2', dffAlignedMat2);
        setappdata(f,'fts2',ftsLstE2);
        if ~isempty(evtGloLst2)
            [ftsLstGloE2, dffMatGlo2, dMatGlo2,dffAlignedMatGlo2] = fea.getFeaturesTop(datOrg2, evtGloLst2, opts, gg);
            ftsLstGloE2.channel = 1;
            setappdata(f, 'dffMatGlo2', dffMatGlo2);
            setappdata(f, 'dMatGlo2', dMatGlo2);
            setappdata(f, 'dffAlignedMatGlo2', dffAlignedMatGlo2);
            setappdata(f, 'ftsGlo2',ftsLstGloE2);
        end
    end
    % filter table init
    ui.detect.filterInit([],[],f);

    %% propgation metric
    if opts.propMetric || opts.networkFeatures
        % gather data
        fprintf('Gathering data ...\n')
        ov0 = ov('Events_Red');
        datR1 = fea.reconstructDatR(ov0,sz);

        if ~isempty(evtGloLst1)
            ov0 = ov('Global Events_Red');
            datRGlo1 = fea.reconstructDatR(ov0,sz);
        end
        
        if(~opts.singleChannel)
            ov0 = ov('Events_Green');
            datR2 = fea.reconstructDatR(ov0,sz);
            if ~isempty(evtGloLst2)
                ov0 = ov('Global Events_Green');
                datRGlo2 = fea.reconstructDatR(ov0,sz);
            end
        end
    end

    if opts.propMetric
        waitbar(0.5, gg, 'Propagation Metric');
        % propagation features
        ftsLstE1 = fea.getFeaturesPropTop(datR1, evtLst1, ftsLstE1, opts);
        setappdata(f,'fts1',ftsLstE1);
        if ~isempty(evtGloLst1)
            ftsLstGloE1 = fea.getFeaturesPropTop(datRGlo1, evtGloLst1, ftsLstGloE1, opts);
            setappdata(f,'ftsGlo1',ftsLstGloE1);
        end
        if(~opts.singleChannel)
            ftsLstE2 = fea.getFeaturesPropTop(datR2, evtLst2, ftsLstE2, opts);
            setappdata(f,'fts2',ftsLstE2);
            if ~isempty(evtGloLst2)
                ftsLstGloE2 = fea.getFeaturesPropTop(datRGlo2, evtGloLst2, ftsLstGloE2, opts);
                setappdata(f,'ftsGlo2',ftsLstGloE2);
            end
        end
    end
    
    waitbar(0.8, gg, 'Network features');
    if opts.networkFeatures
        %region, landmark, network and save results
        ftsLstE1 = ui.detect.updtFeatureRegionLandmarkNetworkShow(f, datR1, evtLst1, ftsLstE1, gg,1);
        setappdata(f,'fts1',ftsLstE1);
        if ~isempty(evtGloLst1)
            ftsLstGloE1 = ui.detect.updtFeatureRegionLandmarkNetworkShow(f, datRGlo1, evtGloLst1, ftsLstGloE1, gg,1);
            setappdata(f,'ftsGlo1',ftsLstGloE1);
        end
        if(~opts.singleChannel)
            ftsLstE2 = ui.detect.updtFeatureRegionLandmarkNetworkShow(f, datR2, evtLst2, ftsLstE2, gg,2);
            setappdata(f,'fts2',ftsLstE2);
            if ~isempty(evtGloLst2)
                ftsLstGloE2 = ui.detect.updtFeatureRegionLandmarkNetworkShow(f, datRGlo2, evtGloLst2, ftsLstGloE2, gg,2);
                setappdata(f,'ftsGlo2',ftsLstGloE2);
            end
        end
    end

    btSt = getappdata(f,'btSt');
    btSt.filterMsk1 = true(numel(evtLst1),1);
    btSt.filterMsk2 = true(numel(evtLst2),1);
    setappdata(f,'btSt',btSt);

    ui.over.updtEvtOvShowLst([],[],f);
    waitbar(1, gg);
    % feature table
    ui.detect.getFeatureTable(f);
    fprintf('Done.\n');

    
    delete(gg)
end 



