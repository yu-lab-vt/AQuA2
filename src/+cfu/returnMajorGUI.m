function returnMajorGUI(~,~,fCFU,f)

    setappdata(f,'cfuInfo1',getappdata(fCFU,'cfuInfo1'));
    setappdata(f,'cfuInfo2',getappdata(fCFU,'cfuInfo2'));
    setappdata(f,'cols1',getappdata(fCFU,'cols1'));
    setappdata(f,'cols2',getappdata(fCFU,'cols2'));
    setappdata(f,'colorMap1',getappdata(fCFU,'colorMap1'));
    setappdata(f,'colorMap2',getappdata(fCFU,'colorMap2'));
    setappdata(f,'relation',getappdata(fCFU,'relation'));
    setappdata(f,'groupInfo',getappdata(fCFU,'groupInfo'));
    setappdata(f,'needReCheckCFU',false);
    delete(fCFU);
end

