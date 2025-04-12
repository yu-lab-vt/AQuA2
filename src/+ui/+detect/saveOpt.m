function saveOpt(~,~,f)
    
    optsOrg = getappdata(f,'opts');
    % should update new changing
    fh = guidata(f);
    opts = [];
    opts.filePath1 = optsOrg.filePath1;
    opts.fileName1 = optsOrg.fileName1;
    opts.fileType1 = optsOrg.fileType1;
    opts.filePath2 = optsOrg.filePath2;
    opts.fileName2 = optsOrg.fileName2;
    opts.fileType2 = optsOrg.fileType2;
    opts.sz = optsOrg.sz;
    
    opts.registrateCorrect = find(strcmp(fh.registrateCorrect.Value,fh.registrateCorrect.Items));
    opts.bleachCorrect = find(strcmp(fh.bleachCorrect.Value,fh.bleachCorrect.Items));
    
    opts.medSmo = str2double(fh.medSmo.Value);
    opts.smoXY = str2double(fh.smoXY.Value);
    
    opts.thrARScl = str2double(fh.thrArScl.Value);
    opts.minSize = str2double(fh.minSize.Value);
    opts.maxSize = str2double(fh.maxSize.Value);
    opts.minDur = str2double(fh.minDur.Value);
    opts.circularityThr = str2double(fh.circularityThr.Value);
%     opts.spaMergeDist = str2double(fh.spaMergeDist.Value);
    
    opts.needTemp = fh.needTemp.Value;
    opts.sigThr = str2double(fh.sigThr.Value);
    opts.maxDelay = str2double(fh.maxDelay.Value);
    opts.seedSzRatio = str2double(fh.seedSzRatio.Value);
%     opts.needRefine = fh.needRefine.Value;
%     opts.needGrow = fh.needGrow.Value;
    
    opts.needSpa = fh.needSpa.Value;
    opts.sourceSzRatio = str2double(fh.sourceSzRatio.Value);
    opts.sourceSensitivity = str2double(fh.sourceSensitivity.Value);
    opts.whetherExtend = fh.whetherExtend.Value;

    opts.detectGlo = fh.detectGlo.Value;
    opts.gloDur = str2double(fh.gloDur.Value);

    opts.ignoreTau = fh.ignoreTau.Value;
    opts.propMetric = fh.propMetric.Value;
    opts.networkFeatures = fh.networkFeatures.Value;
    
    opts.gtwSmo = optsOrg.gtwSmo;
    opts.ratio = optsOrg.ratio;
    opts.regMaskGap = optsOrg.regMaskGap;
    opts.regMaskGap = optsOrg.regMaskGap;
    opts.cut = optsOrg.cut;
    opts.movAvgWin = optsOrg.movAvgWin;
    opts.minShow1 = optsOrg.minShow1;
    opts.correctTrend = optsOrg.correctTrend;
    opts.propthrmin = optsOrg.propthrmin;
    opts.propthrmax = optsOrg.propthrmax;
    opts.propthrstep = optsOrg.propthrstep;
    opts.compress = optsOrg.compress;
    opts.gapExt = optsOrg.gapExt;
    opts.frameRate = optsOrg.frameRate;
    opts.spatialRes = optsOrg.spatialRes;
    opts.northx = optsOrg.northx;
    opts.northy = optsOrg.northy;
    opts.TPatch = optsOrg.TPatch;
    opts.maxSpaScale = optsOrg.maxSpaScale;
    opts.minSpaScale = optsOrg.minSpaScale;    
    
    % SP, 18.07.16
    definput = {'_Opt.csv'};
    selname = inputdlg('Type desired suffix for Parameter file name:',...
        'Parameter file',[1 75],definput);
    
    selname = char(selname);
    if isempty(selname)
        selname = '_Opt.csv';
    end
    file0 = [opts.fileName1,selname];
    clear definput selname
    
    %file0 = [opts.fileName,'_AQuA']; SP, 18.07.16
    selpath = uigetdir(opts.filePath1,'Choose output folder');
    path0 = [selpath,filesep];
    if ~isnumeric(selpath)
        ui.proj.struct2csv(opts,[path0,file0]);
    end
    
end