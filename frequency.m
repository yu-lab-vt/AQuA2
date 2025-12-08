% This script is used for calculating event frequency based on certain
% event ROIs concerned. 
% It serves as an alternative for freq in CFU. See res_cfu.cfuInfo1.freq
% Added 2025/12/04

clear; clc;

%% 1. Load Data
disp('Select your .mat file...');
[file, path] = uigetfile('*.mat');
if isequal(file, 0), disp('Selection canceled'); return; end
load(fullfile(path, file), 'res');

% Set the events to consider
rowsList = [1, 13, 17, 20, 30];
results = []; % Initialize struct to store results

fprintf('%-5s | %-6s | %-10s | %-6s | %-10s | %-10s | %-10s\n', ...
        'Event', 'Count', 'MainFreq', 'Method', 'PeakFreq80', 'Max_dff2', 'Max_df');
fprintf('%s\n', repmat('-', 1, 70));

%% 2. Process Each Row
for k = 1:length(rowsList)

    idxList = res.fts1.network.occurSameLocList{rowsList(k), 1};
    if isempty(idxList), continue; end

    cnt = length(idxList);
    
    % --- Signal Peaks (Max dff/df) ---
    max_dff2 = max(res.fts1.curve.dffMax2(idxList));
    max_df   = max(res.fts1.curve.dfMax(idxList));
    
    % --- Frequency Calculation ---
    dt = [];
    mainFreq = 0; 
    methodStr = 'N/A';
    peakFreq80 = NaN;

    if cnt >= 2
        % Get sorted time points
        tPeaks = sort(res.fts1.curve.dffMaxFrame(idxList));
        
        % Calculate intervals (seconds)
        dt = diff(tPeaks) * res.opts.frameRate;
        % dt = dt(dt > 0); % remove zero intervals
        
        if ~isempty(dt)
            % 1. Calculate Dispersion (Coefficient of Variation)
            cv = std(dt) / mean(dt); 
            
            % 2. Dynamic Selection Logic
            if cv > 1.0 
                % High dispersion (bursty) -> Use Median
                mainFreq = median(1 ./ dt);
                methodStr = 'Med';
            else
                % Regular distribution or small N -> Use Mean
                % Formula: (Count-1) / TotalDuration
                mainFreq = 1 / mean(dt); 
                methodStr = 'Mean';
            end
            
            % 3. Peak Frequency (80th Percentile, only if N >= 5)
            if length(dt) >= 5
                peakFreq80 = prctile(1 ./ dt, 80);
            end
        end
    end
    
    % --- Output ---
    % Print to console
    fprintf('%-5d | %-6d | %-10.4f | %-6s | %-10.4f | %-10.4f | %-10.4f\n', ...
            rowsList(k), cnt, mainFreq, methodStr, peakFreq80, max_dff2, max_df);
            
    % Save to struct
    results(end+1).event_id = rowsList(k);
    results(end).count = cnt;
    results(end).mainFreq = mainFreq;
    results(end).method = methodStr;
    results(end).peakFreq80 = peakFreq80;
    results(end).maxDff2 = max_dff2;
    results(end).maxDf = max_df;
    results(end).dt = dt;
end

fprintf('\nDone. Processed %d valid events.\n', length(results));

% Optional: Convert results to table for easier viewing
% T = struct2table(results);