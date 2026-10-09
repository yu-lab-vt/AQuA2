function resetSession(f,clearFileInputs)
%RESETSESSION Discard all data and analysis state associated with a project.
%   This deliberately keeps only application-wide GUI settings.  It is used
%   both by Restart and immediately before loading a new project so stale
%   data cannot survive either navigation path.

if nargin < 2
    clearFileInputs = false;
end

% Rebuild while hidden so resizing the live browser-backed UI cannot show
% controls laid out for the previous main-window dimensions.
originalVisibility = f.Visible;
restoreWindow = onCleanup(@() restoreVisibility(f,originalVisibility));
f.Visible = 'off';

% Loading must preserve only the choices on the import screen. Controls
% themselves are recreated: a previous project may even have deleted or
% replaced them (single-channel brightness controls and 3-D viewers).
fh = guidata(f);
inputNames = {'fIn1','fIn2','preset','tmpRes','spaRes','bdSpa'};
inputValues = struct();
if ~clearFileInputs
    for ii = 1:numel(inputNames)
        name = inputNames{ii};
        if isfield(fh,name) && isvalid(fh.(name))
            inputValues.(name) = fh.(name).Value;
        end
    end
end
dbg = getappdata(f,'dbg');
if isempty(dbg)
    dbg = 0;
end

% CFU figures keep their own derived-data cache.  They must not remain
% usable after the movie that created them has been discarded.
if isappdata(f,'cfuFigures')
    cfuFigures = getappdata(f,'cfuFigures');
    for ii = 1:numel(cfuFigures)
        if isgraphics(cfuFigures(ii))
            delete(cfuFigures(ii));
        end
    end
end
figFav = getappdata(f,'figFav');
if ~isempty(figFav) && isgraphics(figFav)
    delete(figFav);
end

% Remove figure-level interaction state before rebuilding its contents.
f.KeyReleaseFcn = [];
f.WindowButtonDownFcn = [];
f.WindowButtonMotionFcn = [];
f.WindowButtonUpFcn = [];
f.Pointer = 'arrow';
pan(f,'off');
zoom(f,'off');
delete(f.Children);

% These values describe the application window rather than a project.
persistentNames = {'projectSessionCounter'};
allData = getappdata(f);
allNames = fieldnames(allData);
for ii = 1:numel(allNames)
    name = allNames{ii};
    if ~ismember(name,persistentNames)
        rmappdata(f,name);
    end
end

sessionCounter = getappdata(f,'projectSessionCounter');
if isempty(sessionCounter) || ~isscalar(sessionCounter) || ...
        ~isnumeric(sessionCounter)
    sessionCounter = 0;
end
sessionCounter = sessionCounter + 1;
setappdata(f,'projectSessionCounter',sessionCounter);
setappdata(f,'projectSessionId',sessionCounter);
ui.com.addCon(f,dbg);
fh = guidata(f);
for ii = 1:numel(inputNames)
    name = inputNames{ii};
    if isfield(inputValues,name)
        fh.(name).Value = inputValues.(name);
    end
end
f.Name = 'AQUA2';
end

function restoreVisibility(f,visibility)
if isgraphics(f)
    f.Visible = visibility;
    drawnow;
end
end
