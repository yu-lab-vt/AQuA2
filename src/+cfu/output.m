function output(~,~,fCFU,f)
    opts = getappdata(f,'opts');
    fh = guidata(fCFU);
    datPro = util.normalize01(fh.averPro1);

    selpath = uigetdir(opts.filePath1,'Choose output folder');
    if isequal(selpath,0)
        return;
    end
    path0 = [selpath,filesep,opts.fileName1];

    favCFUList = [];
    if isfield(fh,'favCFUs')
        favCFUList = fh.favCFUs;
    end

    cfuOpts = cfu.getCfuOpts(fCFU);
    cfuInfo1 = getappdata(fCFU,'cfuInfo1');
    cfuInfo2 = getappdata(fCFU,'cfuInfo2');
    cfuRelation = getappdata(fCFU,'relation');
    cfuGroupInfo = getappdata(fCFU,'groupInfo');
    save([path0,'_AQuA2_res_cfu.mat'],'cfuInfo1','cfuInfo2','cfuRelation', ...
        'cfuGroupInfo','cfuOpts','datPro','favCFUList');

    % Update 2026-08-07: export favorite CFU event summaries as an English-only Excel table.
    if isempty(favCFUList)
        return;
    end

    fts1 = getappdata(f,'fts1');
    fts2 = getappdata(f,'fts2');
    nCFU1 = size(cfuInfo1,1);
    metrics = {'Mean Event Area'; ...
               'Summed Event Duration'; ...
               'Mean Event Duration'; ...
               'Mean Event FWHM'; ...
               'Mean Event Rise Time'; ...
               'Mean Event Decay Time'; ...
               'Mean Event dF/F AUC'; ...
               'Mean Event Peak dF/F'; ...
               'Max Event Peak dF/F'};
    nMetrics = numel(metrics);
    nFav = numel(favCFUList);
    exportCell = cell(nMetrics + 1,nFav + 1);
    exportCell(2:end,1) = metrics;
    exportCell{1,1} = 'CFU Index';

    for i = 1:nFav
        id = favCFUList(i);
        exportCell{1,i + 1} = id;
        [eventIds,fts] = getCfuEvents(id,nCFU1,cfuInfo1,cfuInfo2,fts1,fts2);
        exportCell(2:end,i + 1) = num2cell(getEventStatistics(fts,eventIds).');
    end

    excelPath = [path0,'_AQuA2_res_favorite_cfu.xlsx'];
    try
        writecell(exportCell,excelPath);
    catch
        xlswrite(excelPath,exportCell);
    end
end

function [eventIds,fts] = getCfuEvents(id,nCFU1,cfuInfo1,cfuInfo2,fts1,fts2)
    eventIds = [];
    fts = [];
    if ~iscell(cfuInfo1) || ~iscell(cfuInfo2) || ~isnumeric(id) || ...
            ~isscalar(id) || ~isfinite(id) || id ~= fix(id)
        return;
    end

    if id > nCFU1 && id <= nCFU1 + size(cfuInfo2,1)
        eventIds = cfuInfo2{id - nCFU1,2};
        fts = fts2;
    elseif id >= 1 && id <= size(cfuInfo1,1)
        eventIds = cfuInfo1{id,2};
        fts = fts1;
    end
end

function statistics = getEventStatistics(fts,eventIds)
    statistics = nan(1,9);
    requiredFields = {'basic','area'; 'curve','duration'; 'curve','width55'; ...
        'curve','rise19'; 'curve','fall91'; 'curve','dffAUC'; 'curve','dffMax'};
    if ~isstruct(fts) || ~isscalar(fts) || ~isnumeric(eventIds)
        return;
    end
    for i = 1:size(requiredFields,1)
        if ~isfield(fts,requiredFields{i,1})
            return;
        end
        featureGroup = fts.(requiredFields{i,1});
        if ~isstruct(featureGroup) || ...
                ~isfield(featureGroup,requiredFields{i,2})
            return;
        end
    end

    nEvents = min([numel(fts.basic.area),numel(fts.curve.duration), ...
        numel(fts.curve.width55),numel(fts.curve.rise19), ...
        numel(fts.curve.fall91),numel(fts.curve.dffAUC),numel(fts.curve.dffMax)]);
    eventIds = eventIds(:);
    % Update 2026-08-07: ignore stale or invalid event references during export.
    eventIds = eventIds(isfinite(eventIds) & eventIds == fix(eventIds) & ...
        eventIds >= 1 & eventIds <= nEvents);
    if isempty(eventIds)
        return;
    end

    eventPeak = fts.curve.dffMax(eventIds);
    statistics = [mean(fts.basic.area(eventIds),'omitnan'), ...
                  sum(fts.curve.duration(eventIds),'omitnan'), ...
                  mean(fts.curve.duration(eventIds),'omitnan'), ...
                  mean(fts.curve.width55(eventIds),'omitnan'), ...
                  mean(fts.curve.rise19(eventIds),'omitnan'), ...
                  mean(fts.curve.fall91(eventIds),'omitnan'), ...
                  mean(fts.curve.dffAUC(eventIds),'omitnan'), ...
                  mean(eventPeak,'omitnan'), ...
                  max(eventPeak,[],'omitnan')];
end
