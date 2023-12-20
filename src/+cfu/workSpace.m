function workSpace(~,~,fCFU,f)
    assignin('base', 'cfuInfo1', getappdata(fCFU,'cfuInfo1'));
    assignin('base', 'cfuInfo2', getappdata(fCFU,'cfuInfo2'));
    assignin('base', 'relation', getappdata(fCFU,'relation'));
    assignin('base', 'groupInfo', getappdata(fCFU,'groupInfo'));
end

