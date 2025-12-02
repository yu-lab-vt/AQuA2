function saveWaves(~,~,fCFU,f)

    opts = getappdata(f,'opts');
    selpath = uigetdir(opts.filePath1,'Choose output folder');
    if selpath==0
        return;
    end
    path0 = [selpath,filesep,opts.fileName1];
    
    if ~exist(path0,'file') && ~isempty(path0)
        mkdir(path0);    
    end
    
    path1 = [path0,filesep,'CFU_waves_org'];
    if ~exist(path1,'file') && ~isempty(path1)
        mkdir(path1);    
    end
    
    fh = guidata(fCFU);
    tb = fh.evtTable;
    dat = tb.Data;

    cfuInfo1 = getappdata(fCFU,'cfuInfo1');
    cfuInfo2 = getappdata(fCFU,'cfuInfo2');
    T = numel(cfuInfo1{1,6});
    for ii=1:size(dat,1)
        if dat{ii,1}==1 && dat{ii,2}==1
            evtID = dat{ii,3};
            curve = cfuInfo1{evtID,6}';
            writetable(table([1:T]',curve),[path1,filesep,'CH1_CFU',num2str(evtID),'.csv']);
        end

        if dat{ii,1}==1 && dat{ii,2}==2
            evtID = dat{ii,3};
            curve = cfuInfo2{evtID,6}';
            writetable(table([1:T]',curve),[path1,filesep,'CH2_CFU',num2str(evtID),'.csv']);
        end
    end
end