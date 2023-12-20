function output(~,~,fCFU,f)
    opts = getappdata(f,'opts');
    
    selpath = uigetdir(opts.filePath1,'Choose output folder');
    path0 = [selpath,filesep,opts.fileName1];
    cfuInfo1 = getappdata(fCFU,'cfuInfo1');
    cfuInfo2 = getappdata(fCFU,'cfuInfo2');
    relation = getappdata(fCFU,'relation');
    groupInfo = getappdata(fCFU,'groupInfo');
    save([path0,'_AQuA_res_cfu.mat'],'cfuInfo1','cfuInfo2','relation','groupInfo');
end

