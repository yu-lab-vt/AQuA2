function aqua_cmd_batch(batchConfigFile,parameterConfigFile)
%AQUA_CMD_BATCH Run AQuA2 batch processing.
%   AQUA_CMD_BATCH() uses cfg/batch.csv and cfg/parameters_for_batch.csv.
%   AQUA_CMD_BATCH(BATCHCONFIGFILE,PARAMETERCONFIGFILE) uses the supplied
%   CSV files instead. Pass [] for either argument to use its default.
%
% Read Me:
% Set pIn to a folder to recursively process every supported input file with
% Preset1. Leave pIn empty to use cfg/batch.csv instead.
% parameters_for_batch.csv defines reusable Preset1, Preset2, ... columns.
% In batch.csv, inputPath is required; outputPath is optional. Empty outputPath
% writes the result alongside its input file.


close all;
clc;
startup;  % initialize
pIn = '';  % Input folder. Leave empty to use cfg/batch.csv.

if nargin < 1 || isempty(batchConfigFile)
    batchConfigFile = fullfile('cfg','batch.csv');
end
if nargin < 2 || isempty(parameterConfigFile)
    parameterConfigFile = fullfile('cfg','parameters_for_batch.csv');
end

batchSet.propMetric = false;    % whether extract propagation-related features
batchSet.networkFeatures = false; % whether extract network features
batchSet.outputMovie = false;    % whether to output movie with detection overlay
batchSet.outputFeatureTable = true; % whether to output feature table

batchSet.batchConfigFile = char(batchConfigFile);
batchSet.parameterConfigFile = char(parameterConfigFile);

% In batch.csv, fill cellMaskPath and landmarkMaskPath for each file.
% Supported formats: AQuA2 region MAT files (variable bd0) and binary TIFFs.
if strlength(string(pIn)) > 0
    batchJobs = collectFolderJobs(pIn);
else
    batchJobs = readBatchJobs(batchSet.batchConfigFile);
end
if isempty(batchJobs)
    error('aqua_cmd_batch:NoInputFiles','No input files were found.');
end

nJobs = height(batchJobs);
fprintf('AQuA2 batch: %d file(s) queued.\n',nJobs);
for xxx = 1:nJobs
    inputPath = char(batchJobs.inputPath(xxx));
    [inputFolder,inputName,inputExtension] = fileparts(inputPath);
    f1 = [inputName,inputExtension];
    fileTimer = tic;
    fprintf('[%d/%d] Processing: %s\n',xxx,nJobs,inputPath);
    %% load setting (you can also manually modify setting here)
    opts = util.parseParam_for_batch(batchJobs.preset(xxx),[],batchSet.parameterConfigFile);
    opts.singleChannel = true;      % batch only leverages single channel for simplicity
    opts.whetherExtend = true;

%     opts.detectGlo = true;
    opts.propMetric = batchSet.propMetric;
    opts.networkFeatures = batchSet.networkFeatures;

    %% load data
    [datOrg1,datOrg2,opts] = burst.prep1(inputFolder,f1,inputFolder,[],[],opts);
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

    %% Load per-file cell boundaries and landmarks from batch.csv
    bd = containers.Map;
    bd('None') = [];
    bd = addBatchRegionFile(bd,batchJobs.cellMaskPath(xxx),'cell',opts,batchSet.batchConfigFile);
    bd = addBatchRegionFile(bd,batchJobs.landmarkMaskPath(xxx),'landmk',opts,batchSet.batchConfigFile);

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
    opts.maxdF1 = min(100,max(dF1(:)));
    if(~opts.singleChannel)
        [dF2,opts] = pre.baselineRemoveAndNoiseEstimation(datOrg2,opts,evtSpatialMask,2,[]);
        opts.maxdF2 = min(100,max(dF2(:)));
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
             [seLst2,subEvtLst2,seLabel2,majorInfo2,opts,sdLst2,~,~] = se.seDetection(dF2,datOrg2,arLst2,opts,[]);
         else
            seLst2 = [];
            subEvtLst2 = [];
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
        gloOpts = opts;
        gloOpts.minDur = opts.gloDur;
        disp('Global signal detection...');
        sz = opts.sz;
        fprintf('Remove detected local events ...\n')
        dF_glo1 = glo.removeDetected(dF1,evt1);
        % active region
        [gloArLst1] = act.acDetect(dF_glo1,gloOpts,evtSpatialMask,1,[]);  % foreground and seed detection
        
        % temporal segmentation
        if(opts.needTemp)
            [gloSeLst1,gloSubEvtLst1,gloSeLabel1,gloMajorInfo1,gloOpts,~,~,~] = se.seDetection(dF_glo1,datOrg1,gloArLst1,gloOpts,[]);
        else
            gloSeLst1 = gloArLst1; 
            gloSubEvtLst1 = gloArLst1; 
            gloSeLabel1 = 1:numel(gloSeLst1);
            gloMajorInfo1 = se.getMajority_Ac(gloSeLst1,gloSeLst1,dF_glo1,gloOpts);
        end
    
        if(opts.needSpa)
            % spatial segmentation
            [gloRiseLst1,gloDatR1,gloEvt1,~] = evt.se2evtTop(dF_glo1,gloSeLst1,gloSubEvtLst1,gloSeLabel1,gloMajorInfo1,gloOpts,[]);
        else
            gloDatR1 = [];
            gloEvt1 = gloSeLst1;
            gloRiseLst1 = [];
        end
        clear dF_glo1;
        
        %% channel 2
        if(~opts.singleChannel)
            fprintf('Remove detected local events ...\n')
            dF_glo2 = glo.removeDetected(dF2,evt2);
            % active region
            [gloArLst2] = act.acDetect(dF_glo2,gloOpts,evtSpatialMask,1,[]);  % foreground and seed detection
            
            % temporal segmentation
            if(opts.needTemp)
                [gloSeLst2,gloSubEvtLst2,gloSeLabel2,gloMajorInfo2,gloOpts,~,~,~] = se.seDetection(dF_glo2,datOrg2,gloArLst2,gloOpts,[]);
            else
                gloSeLst2 = gloArLst2; 
                gloSubEvtLst2 = gloArLst2; 
                gloSeLabel2 = 1:numel(gloSeLst2);
                gloMajorInfo2 = se.getMajority_Ac(gloSeLst2,gloSeLst2,dF_glo2,gloOpts);
            end
        
            if(opts.needSpa)
                % spatial segmentation
                [gloRiseLst2,gloDatR2,gloEvt2,~] = evt.se2evtTop(dF_glo2,gloSeLst2,gloSubEvtLst2,gloSeLabel2,gloMajorInfo2,gloOpts,[]);
            else
                gloDatR2 = [];
                gloEvt2 = gloSeLst2;
                gloRiseLst2 = [];
            end
            clear dF_glo2;
        else
            gloEvt2 = [];gloDatR2 = []; gloRiseLst2 = [];
        end
    else
        gloEvt1 = [];gloDatR1 = []; gloRiseLst1 = [];
        gloEvt2 = [];gloDatR2 = []; gloRiseLst2 = [];
    end

    %% feature extraction
    disp('Feature extration...');
    opts.stdMapOrg = opts.stdMapOrg1;
    opts.maxValueDat = opts.maxValueDat1;
    opts.minValueDat = opts.minValueDat1;
    opts.tempVarOrg = opts.tempVarOrg1;
    opts.correctPars = opts.correctPars1;
    [fts1, dffMat1, dMat1,dffAlignedMat1] = fea.getFeaturesTop(datOrg1, evt1, opts, []);
    fts1.channel = 1;

    if ~isempty(gloEvt1)
        [ftsGlo1, dffMatGlo1, dMatGlo1,dffAlignedMatGlo1] = fea.getFeaturesTop(datOrg1, gloEvt1, opts, []);
        ftsGlo1.channel = 1;
    else
        ftsGlo1 = []; dffAlignedMatGlo1= [];
    end

    if(~opts.singleChannel)
        opts.stdMapOrg = opts.stdMapOrg2;
        opts.maxValueDat = opts.maxValueDat2;
        opts.minValueDat = opts.minValueDat2;
        opts.tempVarOrg = opts.tempVarOrg2;
        opts.correctPars = opts.correctPars2;
        [fts2, dffMat2, dMat2,dffAlignedMat2] = fea.getFeaturesTop(datOrg2, evt2, opts, []);
        fts2.channel = 2;
        if ~isempty(gloEvt2)
            [ftsGlo2, dffMatGlo2, dMatGlo2,dffAlignedMatGlo2] = fea.getFeaturesTop(datOrg2, gloEvt2, opts, []);
            ftsGlo2.channel = 1;
        else
            ftsGlo2 = []; dffAlignedMatGlo2 = [];
        end
    else
        fts2 = []; dffMat2 = []; dMat2 = []; dffAlignedMat2 = [];
        ftsGlo2 = []; dffMatGlo2 = []; dMatGlo2 = []; dffAlignedMatGlo2 = [];
    end

    %% Propagation metric
    if opts.propMetric
        % propagation features
        fts1 = fea.getFeaturesPropTop(datR1, evt1, fts1, opts);
        if ~isempty(gloEvt1)
            ftsGlo1 = fea.getFeaturesPropTop(gloDatR1, gloEvt1, ftsGlo1, opts);
        end
        if(~opts.singleChannel)
            fts2 = fea.getFeaturesPropTop(datR2, evt2, fts2, opts);
            if ~isempty(gloEvt2)
                ftsGlo2 = fea.getFeaturesPropTop(gloDatR2, gloEvt2, ftsGlo2, opts);
            end
        end
    end

    %% network features
    if opts.networkFeatures
        %region, landmark, network and save results
        btSt.filterMsk1 = true(numel(evt1), 1);
        btSt.filterMsk2 = true(numel(evt2), 1);

        fts1 = fea.getNetworkFeatures(datR1,evt1,fts1, btSt, bd, opts, 1);
        if ~isempty(gloEvt1)
            ftsGlo1 = fea.getNetworkFeatures(gloDatR1,gloEvt1,ftsGlo1, btSt, bd, opts, 1);
        end
        if(~opts.singleChannel)
            fts2 = fea.getNetworkFeatures(datR2,evt2,fts2, btSt, bd, opts, 1);
            if ~isempty(gloEvt2)
                ftsGlo2 = fea.getNetworkFeatures(gloDatR2,gloEvt2,ftsGlo2, btSt, bd, opts, 1);
            end
        end
    end
    
    %% gather results
    disp('Gathering result...');
    % export 
    res.maxVal = opts.maxValueDat1;
    vSave0 = {...  % basic variables for results analysis
        'opts','ov','datOrg1','datOrg2','evt1','evt2','fts1','fts2','dffMat1','dMat1',...
        'dffMat2','dMat2','riseLst1','riseLst2','dF1','dF2','gloEvt1','gloEvt2','ftsGlo1','ftsGlo2','gloRiseLst1','gloRiseLst2'};

    ov = containers.Map('UniformValues',0);
    ov('None') = [];
    ovName = 'Events';
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
        ov1 = ui.over.getOv([],gloEvt1,opts.sz,gloDatR1,1);
        ov1.name = ovName;
        ov1.colorCodeType = {'Random'};
        ov([ovName,'_Red']) = ov1;
        ov2 = ui.over.getOv([],gloEvt2,opts.sz,gloDatR2,2);
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
    res.bd = bd;
    
    %% save output
    disp('Saving result...');
    name = inputName;
    pOut_each = char(batchJobs.outputPath(xxx));
    if isempty(pOut_each)
        pOut_each = inputFolder;
    end
    if ~isfolder(pOut_each)
        mkdir(pOut_each);
    end
    pOut_each = [pOut_each,filesep];
    save([pOut_each,name,'_AQuA2.mat'], 'res','-v7.3', '-nocompression');   

    %% FeatureTable
    if batchSet.outputFeatureTable
        if bd.isKey('landmk')
            bd1 = bd('landmk');
            if opts.sz(3)==1
                lmkLst = cell(numel(bd1),1);
                for ii=1:numel(bd1)
                    lmkLst{ii} = bd1{ii}{1};
                end
            else
                lmkLst = [];
            end
        else
            lmkLst = [];
        end
        fpath = pOut_each(1:end-1);
        fname = [name,'_AQuA2'];

        ftTb1 = fea.getFeatureTable00(fts1,lmkLst,[]);
        writetable(ftTb1,[fpath,filesep,fname,'_Ch1.csv'],'WriteVariableNames',0,'WriteRowNames',1);
        if(opts.detectGlo)
            ftTbGlo1 = fea.getFeatureTable00(ftsGlo1,lmkLst,[]);
            writetable(ftTbGlo1,[fpath,filesep,fname,'_Glo_Ch1.xlsx'],'WriteVariableNames',0,'WriteRowNames',1);
        end
        if(~opts.singleChannel)
            ftTb2 = fea.getFeatureTable00(fts2,lmkLst,[]);
            writetable(ftTb2,[fpath,filesep,fname,'_Ch2.csv'],'WriteVariableNames',0,'WriteRowNames',1);
            if(opts.detectGlo)
                ftTbGlo2 = fea.getFeatureTable00(ftsGlo2,lmkLst,[]);
                writetable(ftTbGlo2,[fpath,filesep,fname,'_Glo_Ch2.xlsx'],'WriteVariableNames',0,'WriteRowNames',1);
            end
        else
            ftTb2 = [];
            ftTbGlo2 = [];
        end
    
        %% curves
        fea.outputCurves(dffAlignedMat1, fts1, dffAlignedMat2, fts2, opts, fpath, fname);
        if(opts.detectGlo)
            fea.outputCurves(dffAlignedMatGlo1, ftsGlo1, dffAlignedMatGlo2, ftsGlo2, opts, fpath, [fname,'_Glo']);
        end
    
        %% for each region
        fea.outputRegions(fts1, ftTb1, [], fts2, ftTb2, [], bd, opts, fpath, fname);
        if(opts.detectGlo)
            fea.outputRegions(ftsGlo1, ftTbGlo1, [], ftsGlo2, ftTbGlo2, [], bd, opts, fpath, fname);
        end
    
        %% rising maps
        fea.outputRisingMap([],[],riseLst1, 1:numel(riseLst1), riseLst2, 1:numel(riseLst2), opts, fpath, [fname, '_risingMaps']);
        if(opts.detectGlo)
            fea.outputRisingMap([],[],gloRiseLst1, 1:numel(gloRiseLst1), gloRiseLst2, 1:numel(gloRiseLst2), opts, fpath ,[fname, '_risingMaps_Glo']);
        end

    end

    %% export movie
    if batchSet.outputMovie
        if opts.sz(3) == 1
            ov1 = plt.regionMapWithData(evt1,datOrg1,0.5,datR1);
            ov1 = double(ov1)/255.0;
            if ~opts.singleChannel
                ov2 = plt.regionMapWithData(evt2,datOrg2,0.5,datR2);
                ov2 = double(ov2)/255.0;
                io.writeTiffSeq([pOut_each,name,'_AQuA2_Channel_1.tif'],ov1,8);
                io.writeTiffSeq([pOut_each,name,'_AQuA2_Channel_2.tif'],ov2,8);
            else
                io.writeTiffSeq([pOut_each,name,'_AQuA2_Movie.tif'],ov1,8);
            end
        else
            % 3D
            ov1 = plt.regionMapWithData(evt1,datOrg1,0.5,datR1);
            ov1 = double(ov1)/255.0;
            for tt = 1:opts.sz(4)
                io.writeTiffSeq([pOut_each,name,'_AQuA2_Ch1_Frame',num2str(tt),'.tif'],ov1(:,:,:,:,tt),8);
            end
            if ~opts.singleChannel
                ov2 = plt.regionMapWithData(evt2,datOrg2,0.5,datR2);
                ov2 = double(ov2)/255.0;
                for tt = 1:opts.sz(4)
                    io.writeTiffSeq([pOut_each,name,'_AQuA2_Ch2_Frame',num2str(tt),'.tif'],ov2(:,:,:,:,tt),8);
                end
            end
        end
    end
    fprintf('[%d/%d] Done in %.1f s. Output: %s\n', ...
        xxx,nJobs,toc(fileTimer),pOut_each);
end
end

function batchJobs = readBatchJobs(cfgFile)
% Read one input job per batch.csv row. Empty outputPath uses input folder.
if ~isfile(cfgFile)
    error('aqua_cmd_batch:MissingBatchConfig', ...
        'Cannot find batch configuration file: %s',cfgFile);
end

% Explicit comma delimiter prevents path separators in inputPath from being
% mistaken for the CSV delimiter during automatic import detection.
batchJobs = readtable(cfgFile,'TextType','string','Delimiter',',');
requiredColumns = {'inputPath','outputPath','preset','cellMaskPath','landmarkMaskPath'};
missingColumns = requiredColumns(~ismember(requiredColumns,batchJobs.Properties.VariableNames));
if ~isempty(missingColumns)
    error('aqua_cmd_batch:InvalidBatchConfig', ...
        'batch.csv must contain columns: %s. Missing: %s', ...
        strjoin(requiredColumns,', '),strjoin(missingColumns,', '));
end
batchJobs = batchJobs(:,requiredColumns);
batchJobs.inputPath = strtrim(string(batchJobs.inputPath));
batchJobs.outputPath = strtrim(string(batchJobs.outputPath));
batchJobs.cellMaskPath = strtrim(string(batchJobs.cellMaskPath));
batchJobs.landmarkMaskPath = strtrim(string(batchJobs.landmarkMaskPath));
batchJobs = batchJobs(~ismissing(batchJobs.inputPath) & batchJobs.inputPath ~= "",:);
if isempty(batchJobs)
    return
end

batchJobs.preset = str2double(string(batchJobs.preset));
if any(~isfinite(batchJobs.preset) | batchJobs.preset < 1 | batchJobs.preset ~= round(batchJobs.preset))
    error('aqua_cmd_batch:InvalidPreset', ...
        'Every preset in batch.csv must be a positive integer.');
end
for row = 1:height(batchJobs)
    batchJobs.inputPath(row) = resolveExistingPath(batchJobs.inputPath(row),cfgFile,'input');
    [~,~,extension] = fileparts(batchJobs.inputPath(row));
    if ~any(strcmpi(extension,{'.tif','.tiff','.avi','.mat'}))
        error('aqua_cmd_batch:UnsupportedInputFile', ...
            'Unsupported input file in batch.csv: %s',batchJobs.inputPath(row));
    end
    batchJobs.outputPath(row) = resolveOutputPath(batchJobs.outputPath(row),cfgFile);
end
end

function batchJobs = collectFolderJobs(inputFolder)
inputFolder = char(inputFolder);
if ~isfolder(inputFolder)
    error('aqua_cmd_batch:InputFolderNotFound', ...
        'Input folder does not exist: %s',inputFolder);
end
files = [dir(fullfile(inputFolder,'**','*.tif')); ...
         dir(fullfile(inputFolder,'**','*.tiff')); ...
         dir(fullfile(inputFolder,'**','*.avi')); ...
         dir(fullfile(inputFolder,'**','*.mat'))];
if ~isempty(files)
    files = files(~endsWith({files.name},'_AQuA2.mat','IgnoreCase',true));
end
inputPaths = string(fullfile({files.folder},{files.name}))';
nFiles = numel(inputPaths);
batchJobs = table(inputPaths,repmat("",nFiles,1),ones(nFiles,1), ...
    repmat("",nFiles,1),repmat("",nFiles,1), ...
    'VariableNames',{'inputPath','outputPath','preset','cellMaskPath','landmarkMaskPath'});
end

function bd = addBatchRegionFile(bd,regionPath,label,opts,cfgFile)
regionPath = strtrim(string(regionPath));
if ismissing(regionPath) || regionPath == ""
    return
end

regionPath = resolveExistingPath(regionPath,cfgFile,'region');
[~,~,extension] = fileparts(regionPath);
switch lower(extension)
    case '.mat'
        loadedRegion = load(regionPath,'bd0');
        if ~isfield(loadedRegion,'bd0')
            error('aqua_cmd_batch:InvalidRegionMat', ...
                'Region MAT file must contain variable "bd0": %s',regionPath);
        end
        bd(label) = loadedRegion.bd0;
    case {'.tif','.tiff'}
        if opts.sz(3) ~= 1
            error('aqua_cmd_batch:TiffMaskFor3D', ...
                'TIFF region masks are supported for 2-D+time data only. Use a bd0 MAT file for: %s',regionPath);
        end
        bd(label) = tiffMaskToRegions(regionPath,opts);
    otherwise
        error('aqua_cmd_batch:UnsupportedRegionFile', ...
            'Unsupported region file "%s". Use a .mat, .tif, or .tiff file.',regionPath);
end
end

function resolvedPath = resolveExistingPath(pathValue,cfgFile,pathKind)
% Relative paths are interpreted relative to the folder containing batch.csv.
resolvedPath = char(pathValue);
if ~isfile(resolvedPath) && ~isAbsolutePath(resolvedPath)
    resolvedPath = fullfile(fileparts(cfgFile),resolvedPath);
end
if ~isfile(resolvedPath)
    error('aqua_cmd_batch:FileNotFound', ...
        'Cannot find %s file: %s',pathKind,pathValue);
end
end

function outputPath = resolveOutputPath(outputPath,cfgFile)
if ismissing(outputPath) || outputPath == ""
    outputPath = "";
    return
end
outputPath = char(outputPath);
if ~isfolder(outputPath) && ~isAbsolutePath(outputPath)
    outputPath = fullfile(fileparts(cfgFile),outputPath);
end
outputPath = string(outputPath);
end

function tf = isAbsolutePath(pathValue)
pathValue = string(pathValue);
tf = startsWith(pathValue,"\\") || ~isempty(regexp(char(pathValue),'^[A-Za-z]:[\\/]','once'));
end

function bd0 = tiffMaskToRegions(regionPath,opts)
rawMask = imread(regionPath);
if ndims(rawMask) == 3
    rawMask = max(rawMask,[],3);  % Accept RGB mask images.
end
if ~ismatrix(rawMask)
    error('aqua_cmd_batch:InvalidTiffMask', ...
        'TIFF mask must contain one two-dimensional image: %s',regionPath);
end

mask = rawMask ~= 0;  % Non-zero pixels are included in the region.
targetSize = opts.sz(1:2);
fullSize = targetSize + 2*opts.regMaskGap;
if isequal(size(mask),targetSize)
    % Mask is already in AQuA2 working coordinates.
elseif isequal(size(mask),fullSize)
    gap = opts.regMaskGap;
    mask = mask(gap+1:end-gap,gap+1:end-gap);
else
    error('aqua_cmd_batch:MaskSizeMismatch', ...
        ['TIFF mask size is [%d %d]; expected image size [%d %d] or ' ...
         'uncropped size [%d %d]: %s'], ...
        size(mask,1),size(mask,2),targetSize,fullSize,regionPath);
end

components = bwconncomp(mask,8);
if components.NumObjects == 0
    warning('aqua_cmd_batch:EmptyTiffMask', ...
        'TIFF region mask has no non-zero pixels: %s',regionPath);
end
bd0 = cell(components.NumObjects,1);
for componentIndex = 1:components.NumObjects
    pixels = components.PixelIdxList{componentIndex};
    componentMask = false(targetSize);
    componentMask(pixels) = true;
    bd0{componentIndex} = {bwboundaries(componentMask),pixels,'imported','None'};
end
end

