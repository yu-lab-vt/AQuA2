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
%% setting
pIn = 'F:\Test_data\Check\'; %% tif folder
pOut = 'F:\Test_data\Check\'; %% tif folder

whetherUpdateRes = true;
whetherOutputCFURes = true;

cfuOpts.cfuDetect.overlapThr1 = 0.5;    % channel 1, overlap threshold
cfuOpts.cfuDetect.overlapThr2 = 0.5;    % channel 2, overlap threshold
cfuOpts.cfuDetect.minNumEvt1 = 3;       % channel 1, minimum number of events in one CFU
cfuOpts.cfuDetect.minNumEvt2 = 3;       % channel 2, minimum number of events in one CFU

cfuOpts.cfuAnalysis.maxDist = 10;       % maximum distance (time points) for judging cooccurrence
cfuOpts.cfuAnalysis.shift = 0;          % shift distance (time points) for judging cooccurrence

cfuOpts.cfuGroup.pValueThr = 1e-5;         % p value threshold for grouping CFU
cfuOpts.cfuGroup.cfuNumThr = 3;         % minimum number of CFUs in one group

%% For cell boundary and landmark
mkdir(pOut);
files = dir(fullfile(pIn,'*AQuA2.mat'));

for xxx = 1:numel(files)
    f1 = files(xxx).name; 
    %% load result
    load([pIn, f1]);
    
    %% cfuDetect
    [cfuInfo1, cfuInfo2] = cfu.CFUdetectScript(res,cfuOpts);

    %% calculate dependency
    cfuRelation = cfu.calAllDependencyScript(cfuInfo1, cfuInfo2, cfuOpts);

    %% group CFUs
    cfuGroupInfo = cfu.groupCFUscript(cfuInfo1, cfuInfo2, cfuRelation, cfuOpts);

    if whetherUpdateRes
        res.cfuInfo1 = cfuInfo1;
        res.cfuInfo2 = cfuInfo2;
        res.cfuRelation = cfuRelation;
        res.cfuGroupInfo = cfuGroupInfo;
        save([pIn, f1],'res','-v7.3');
    end

    if whetherOutputCFURes
        cfures.cfuInfo1 = cfuInfo1;
        cfures.cfuInfo2 = cfuInfo2;
        cfures.cfuRelation = cfuRelation;
        cfures.cfuGroupInfo = cfuGroupInfo;
        save([pIn,f1(1:end-4),'_res_cfu.mat'],'cfuInfo1','cfuInfo2','cfuRelation','cfuGroupInfo','cfuOpts');
    end
end
