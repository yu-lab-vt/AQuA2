%% setup
% 
% Read Me:
% Please set cfuOpts in the following lines first.

% 'pIn' is the folder containing AQuA2 saved files from `aqua_cmd_batch`.

close all;
clc;
clearvars
startup;  % initialize
%% setting
pIn = 'F:\Test_data\Check\'; % AQuA2 saved files folder
pOut = 'F:\Test_data\CheckCFU\'; % The folder for cfu results

whetherUpdateRes = true;    % whether to update saved files
whetherOutputCFURes = true; % whether to output cfu results in pOut folder

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
    
    datPro = rescale(mean(single(res.datOrg1), 4));

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
        save([pOut,f1(1:end-4),'_res_cfu.mat'],'cfuInfo1','cfuInfo2','cfuRelation','cfuGroupInfo','cfuOpts','datPro');
    end
end
