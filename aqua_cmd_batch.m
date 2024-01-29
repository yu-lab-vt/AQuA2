%% setup
% 
% Read Me:
% Please set 'AQuA/cfg/parameters_for_batch' first.
% The script will read the parameters from that excel to deal with data.
% How many files you have, how many parameter settings should be in that excel.

% 'p0' is the folder containing tifs you want to deal with.
% Suggest sort the files in order, so that you can set the parameters 


close all;
clc;
clearvars
startup;  % initialize
pIn = 'V:\GrabATP_H1Rpharmacology_forXuelong\noAntagonist\'; %% tif folder
pOut = 'V:\GrabATP_H1Rpharmacology_forXuelong\noAntagonist\'; %% tif folder

%% For cell boundary and landmark
p_cell = '';   % cell boundary path, if you have
p_landmark = '';   % landmark path, if you have

bd = containers.Map;
bd('None') = [];
if(~strcmp(p_cell,''))
    cell_region = load(p_cell);
    bd('cell') = cell_region.bd0;
    
end
if(~strcmp(p_landmark,''))
    landmark = load(p_landmark);
    bd('landmk') = landmark.bd0;
end

mkdir(pOut);
files = dir(fullfile(pIn,'*.tif'));
    
for xxx = 1:numel(files)
    f1 = files(xxx).name; 
    %% load setting
    opts = util.parseParam_for_batch(xxx);
    opts.singleChannel = true;
    opts.whetherExtend = true;
    
    %% load data
    disp('Loading...');
    [datOrg1,datOrg2,opts] = burst.prep1(pIn,f1,pIn,[],[],opts);
    [H,W,L,T] = size(datOrg1);
    opts.singleChannel = isempty(datOrg2);
    %% preprocessing
    disp('Preprocessing...');
    if(opts.registrateCorrect == 2)
        [datOrg1,datOrg2] = reg.regCrossCorrelation(datOrg1,datOrg2);
    elseif(opts.registrateCorrect == 3)
        if(opts.singleChannel)
            [datOrg1,datOrg2] = reg.regCrossCorrelation(datOrg1,datOrg2);
        else
            [datOrg2,datOrg1] = reg.regCrossCorrelation(datOrg2,datOrg1);
        end
    else
        tforms = [];
    end
  
    if(opts.bleachCorrect==2)
        [datOrg1] = pre.bleach_correct(datOrg1);
        if(~opts.singleChannel)
            [datOrg2] = pre.bleach_correct(datOrg2);
        end
    elseif(opts.bleachCorrect==3)
        [datOrg1] = pre.bleach_correct2(datOrg1,opts);
        if(~opts.singleChannel)
            [datOrg2] = pre.bleach_correct2(datOrg2,opts);
        end
    end
    opts.sz = size(datOrg1); sz = opts.sz;

    %% Noise estimation and baseline estimation
    evtSpatialMask = true(sz(1:3));
    if bd.isKey('cell')
        bd0 = bd('cell');
        if sz(3)==1
            if numel(bd0) > 0
                evtSpatialMask = false(sz(1:3));
                for ii=1:numel(bd0)
                    p0 = bd0{ii}{2};
                    evtSpatialMask(p0) = true;
                end
            end
        else
            evtSpatialMask = bd0;
        end
    end
    
    [dF1,opts] = pre.baselineRemoveAndNoiseEstimation(datOrg1,opts,evtSpatialMask,1,[]);
    opts.maxdF1 = min(20,max(dF1(:)));
    if(~opts.singleChannel)
        [dF2,opts] = pre.baselineRemoveAndNoiseEstimation(datOrg2,opts,evtSpatialMask,2,[]);
        opts.maxdF2 = min(20,max(dF2(:)));
    else
        dF2 = []; 
    end

    %% Active region detection
    disp('Active region detection...');
    [arLst1] = act.acDetect(dF1,opts,evtSpatialMask,1,[]);
    if(~opts.singleChannel)
        [arLst2] = act.acDetect(dF2,opts,evtSpatialMask,2,[]);  % foreground and seed detection
    else
        arLst2 = [];
    end

    %% temporal segmentation
    disp('Temporal segmentation...');
    opts.step = 0.5;
    if(opts.needTemp)
         [seLst1,subEvtLst1,seLabel1,majorInfo1,opts,sdLst1,~,~] = se.seDetection(dF1,datOrg1,arLst1,opts,[]);
         if(~opts.singleChannel)
             [seLst2,subEvtLst2,seLabel2,majorInfo2,opts,sdLst2,~,~] = se.seDetection(dF2,dFOrg2,arLst2,opts,[]);
         end
    else
        seLst1 = arLst1;
        seLst2 = arLst2;
        subEvtLst1 = arLst1; 
        subEvtLst2 = arLst2; 
        seLabel1 = 1:numel(seLst1);
        seLabel2 = 1:numel(seLst2);
        majorInfo1 = se.getMajority_Ac(seLst1,seLst1,dF1,opts);
        majorInfo2 = se.getMajority_Ac(seLst2,seLst2,dF2,opts);
    end

    %% spatial segmentation
    disp('Spatial segmentation...');
    if(opts.needSpa)
        [riseLst1,datR1,evt1,~] = evt.se2evtTop(dF1,seLst1,subEvtLst1,seLabel1,majorInfo1,opts,[]);
        if(~opts.singleChannel)
            [riseLst2,datR2,evt2,~] = evt.se2evtTop(dF2,seLst2,subEvtLst2,seLabel2,majorInfo2,opts,[]);
        else
            evt2 = [];datR2 = [];riseLst2 = [];
        end
    else
        evt1 = seLst1; evt2 = seLst2;
        datR1 = 255*uint8(ones(size(datOrg1))); datR2 = datR1;
        riseLst1 = []; riseLst2 = [];
    end

    %% Global signal detection
    if(opts.detectGlo)
        disp('Global signal detection...');
        sz = opts.sz;
        % channel 1        
        dF_glo1 = glo.removeDetected(dF1,evt1);
        % active region
        [arLst1] = act.acDetect(dF_glo1,opts,evtSpatialMask,1,[]);  % foreground and seed detection
        % temporal segmentation
        if(fh.needTemp.Value)
            [seLst1,subEvtLst1,seLabel1,majorInfo1,opts,~,~,~] = se.seDetection(dF_glo1,datOrg1,arLst1,opts,[]);
            if(fh.needSpa.Value)
                % spatial segmentation
                [gloRiseLst1,datRGlo1,gloEvt1,~] = evt.se2evtTop(dF_glo1,seLst1,subEvtLst1,seLabel1,majorInfo1,opts,[]);
            else
                gloEvt1 = seLst1; gloRiseLst1 = []; datRGlo1 = 255*uint8(ones(size(datOrg1)));
            end
        else
            gloEvt1 = arLst1; gloRiseLst1 = [];datRGlo1 = 255*uint8(ones(size(datOrg1)));
        end
        
        %% channel 2
        if(~opts.singleChannel)
            dF_glo2 = glo.removeDetected(dF2,evt2);
            % active region
            [arLst2] = act.acDetect(dF_glo2,opts,evtSpatialMask,2,[]);  % foreground and seed detection
    
            % temporal segmentation
            if(fh.needTemp.Value)
                [seLst2,subEvtLst2,seLabel2,majorInfo2,opts,~,~,~] = se.seDetection(dF_glo2,datOrg2,arLst2,opts,[]);
                if(fh.needSpa.Value)
                    [gloRiseLst2,datRGlo2,gloEvt2,~] = evt.se2evtTop(dF_glo2,seLst2,subEvtLst2,seLabel2,majorInfo2,opts,[]);
                else
                    gloEvt2 = seLst2; gloRiseLst2 = []; datRGlo2 = 255*uint8(ones(size(datOrg1)));
                end
            else
                gloEvt2 = arLst2; gloRiseLst2 = []; datRGlo2 = 255*uint8(ones(size(datOrg1)));
            end
        else
            gloEvt2 = [];datRGlo2 = []; gloRiseLst2 = [];
        end
    else
        gloEvt1 = []; gloRiseLst1 = [];gloEvt2 = []; gloRiseLst2= [];
    end

    %% feature extraction
    disp('Feature extration...');
    opts.stdMapOrg = opts.stdMapOrg1;
    opts.maxValueDat = opts.maxValueDat1;
    opts.minValueDat = opts.minValueDat1;
    opts.tempVarOrg = opts.tempVarOrg1;
    opts.correctPars = opts.correctPars1;
    [fts1, dffMat1, dMat1,~] = fea.getFeaturesTop(datOrg1, evt1, opts, []);
    fts1.channel = 1;

    if ~isempty(gloEvt1)
        [ftsGlo1, dffMatGlo1, dMatGlo1,dffAlignedMatGlo1] = fea.getFeaturesTop(datOrg1, gloEvt1, opts, []);
        ftsGlo1.channel = 1;
    else
        ftsGlo1 = [];
    end

    if(~opts.singleChannel)
        opts.stdMapOrg = opts.stdMapOrg2;
        opts.maxValueDat = opts.maxValueDat2;
        opts.minValueDat = opts.minValueDat2;
        opts.tempVarOrg = opts.tempVarOrg2;
        opts.correctPars = opts.correctPars2;
        [fts2, dffMat2, dMat2,~] = fea.getFeaturesTop(datOrg2, evt2, opts, gg);
        fts2.channel = 2;
        if ~isempty(gloEvt2)
            [ftsGlo2, dffMatGlo2, dMatGlo2,~] = fea.getFeaturesTop(datOrg2, gloEvt2, opts, []);
            ftsGlo2.channel = 1;
        else
            ftsGlo2 = [];
        end
    else
        fts2 = []; dffMat2 = []; dMat2 = []; ftsGlo2 = [];
    end

    %% Propagation metric
    if opts.propMetric
        % propagation features
        fts1 = fea.getFeaturesPropTop(datR1, evt1, fts1, opts);
        if ~isempty(evtGloLst1)
            ftsGlo1 = fea.getFeaturesPropTop(datRGlo1, evtGloLst1, ftsGlo1, opts);
        end
        if(~opts.singleChannel)
            fts2 = fea.getFeaturesPropTop(datR2, evt2, fts2, opts);
            if ~isempty(evtGloLst2)
                ftsGlo2 = fea.getFeaturesPropTop(datRGlo2, evtGloLst2, ftsGlo2, opts);
            end
        end
    end

    %% save output
    disp('Gathering result...');
    % export 
    res.maxVal = opts.maxValueDat1;
    vSave0 = {...  % basic variables for results analysis
        'opts','ov','datOrg1','datOrg2','evt1','evt2','fts1','fts2','dffMat1','dMat1',...
        'dffMat2','dMat2','riseLst1','riseLst2','dF1','dF2','gloEvt1','gloEvt2','ftsGlo1','ftsGlo2','gloRiseLst1','gloRiseLst2'};

    ov = containers.Map('UniformValues',0);
    ov('None') = [];
    ovName = 'Events';
    fprintf('Overlay for events...\n')
    ov1 = ui.over.getOv([],evt1,opts.sz,datR1,1);
    ov1.name = ovName;
    ov1.colorCodeType = {'Random'};
    ov([ovName,'_Red']) = ov1;
    ov2 = ui.over.getOv([],evt2,opts.sz,datR2,2);
    ov2.name = ovName;
    ov2.colorCodeType = {'Random'};
    ov([ovName,'_Green']) = ov2;
    if(opts.detectGlo)
        ovName = 'Global Events';
        ov1 = ui.over.getOv([],gloEvt1,opts.sz,datRGlo1,1);
        ov1.name = ovName;
        ov1.colorCodeType = {'Random'};
        ov([ovName,'_Red']) = ov1;
        ov2 = ui.over.getOv([],gloEvt2,opts.sz,datRGlo2,2);
        ov2.name = ovName;
        ov2.colorCodeType = {'Random'};
        ov([ovName,'_Green']) = ov2;
    end

    vSave = vSave0;
    res = [];
    for ii=1:numel(vSave)
        v0 = vSave{ii};
        res.(v0) = eval(v0);
    end
    if opts.BitDepth == 8
        res.datOrg1 = uint8(res.datOrg1*(opts.maxValueDat1 - opts.minValueDat1)+opts.minValueDat1);
        if ~isempty(res.datOrg2)
            res.datOrg2 = uint8(res.datOrg2*(opts.maxValueDat2 - opts.minValueDat2)+opts.minValueDat2);
        end
    else
        res.datOrg1 = uint16(res.datOrg1*(opts.maxValueDat1 - opts.minValueDat1)+opts.minValueDat1);
        if ~isempty(res.datOrg2)
            res.datOrg2 = uint16(res.datOrg2*(opts.maxValueDat2 - opts.minValueDat2)+opts.minValueDat2);
        end
    end

    res.stg.post = 1;
    res.stg.detect = 1;

    bd = containers.Map;
    bd('None') = [];
    res.bd = bd;

    %% save output
    name = [f1(1:end-4)];
    disp('Saving result...');
    save([pOut,name,'_AQuA2.mat'], 'res','-v7.3');   
end
