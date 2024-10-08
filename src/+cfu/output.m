function output(~,~,fCFU,f)
    opts = getappdata(f,'opts');
    fh = guidata(fCFU);
    datPro = rescale(fh.averPro1);
    selpath = uigetdir(opts.filePath1,'Choose output folder');
    path0 = [selpath,filesep,opts.fileName1];
    cfuOpts = cfu.getCfuOpts(fCFU);
    cfuInfo1 = getappdata(fCFU,'cfuInfo1');
    cfuInfo2 = getappdata(fCFU,'cfuInfo2');
    cfuRelation = getappdata(fCFU,'relation');
    cfuGroupInfo = getappdata(fCFU,'groupInfo');
    save([path0,'_AQuA2_res_cfu.mat'],'cfuInfo1','cfuInfo2','cfuRelation','cfuGroupInfo','cfuOpts','datPro');
end

