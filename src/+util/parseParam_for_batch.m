function [opts,optsInfo,optsName,cfg] = parseParam_for_batch(presetNum,~,cfgFile)
%GETPARAM read parameter configuration file

if ~exist('presetNum','var')
    presetNum = 1;
end

if ~exist('cfgFile','var')
    cfgFile = 'parameters_for_batch.csv';
end

opts = [];
optsInfo = [];
optsName = [];

cfg = readtable(cfgFile,'TextType','string');
% cfg = cfg(2:end,:);

% remove empty lines
cfg = cfg(~ismissing(cfg.Name) & strtrim(string(cfg.Name)) ~= "",:);

presetName = sprintf('Preset%d',presetNum);
parameterColumn = presetName;
if ~ismember(parameterColumn,cfg.Properties.VariableNames)
    legacyName = sprintf('File%d',presetNum);
    if ismember(legacyName,cfg.Properties.VariableNames)
        parameterColumn = legacyName;
    else
        error('util:parseParam_for_batch:MissingPreset', ...
            'Cannot find preset column "%s" in %s.',presetName,cfgFile);
    end
end
vName = string(cfg{:,2});

val0 = cfg.(parameterColumn);

for ii=1:numel(vName)
    tmp = val0(ii);
    if iscell(tmp)
        tmp = tmp{1};
    end
    if ischar(tmp) || isstring(tmp)
        tmp = str2double(tmp);
    end
    opts.(char(vName(ii))) = tmp;
end

end


