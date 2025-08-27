function workSpace(~,~,fCFU,f)
    assignin('base', 'cfuOpts', cfu.getCfuOpts(fCFU));
    assignin('base', 'cfuInfo1', getappdata(fCFU,'cfuInfo1'));
    assignin('base', 'cfuInfo2', getappdata(fCFU,'cfuInfo2'));
    assignin('base', 'cfuRelation', getappdata(fCFU,'relation'));
    assignin('base', 'cfuGroupInfo', getappdata(fCFU,'groupInfo'));
    msgbox('CFU data sent successfully!', 'Success');
end

