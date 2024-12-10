function loadOpt(~,~,f)
    
    %file0 = [opts.fileName,'_AQuA']; SP, 18.07.16
    opts = getappdata(f,'opts');
    [file,path] = uigetfile('.csv','Choose Parameter file',opts.filePath1);
    if ~isnumeric([path,file])
        optsLoad = ui.proj.csv2struct([path,file]);
        
        opts.registrateCorrect = optsLoad.registrateCorrect;
        opts.bleachCorrect = optsLoad.bleachCorrect;
        opts.medSmo = optsLoad.medSmo;
        opts.smoXY = optsLoad.smoXY;

        opts.thrARScl = optsLoad.thrARScl;
        opts.minSize = optsLoad.minSize;
        opts.maxSize = optsLoad.maxSize;
        opts.minDur = optsLoad.minDur;
        opts.circularityThr = optsLoad.circularityThr;
%         opts.spaMergeDist = optsLoad.spaMergeDist;

        opts.needTemp = optsLoad.needTemp;
        opts.sigThr = optsLoad.sigThr;
        opts.maxDelay = optsLoad.maxDelay;
        opts.seedSzRatio = optsLoad.seedSzRatio;
%         opts.needRefine = optsLoad.needRefine;
%         opts.needGrow = optsLoad.needGrow;

        opts.needSpa = optsLoad.needSpa;
        opts.sourceSzRatio = optsLoad.sourceSzRatio;
        opts.sourceSensitivity = optsLoad.sourceSensitivity;

        opts.detectGlo = optsLoad.detectGlo;
        opts.gloDur = optsLoad.gloDur;

        opts.ignoreTau = optsLoad.ignoreTau;
        opts.propMetric = optsLoad.propMetric;
        opts.networkFeatures = optsLoad.networkFeatures;


        opts.gtwSmo = optsLoad.gtwSmo;
        opts.ratio = optsLoad.ratio;
        opts.regMaskGap = optsLoad.regMaskGap;
        opts.regMaskGap = optsLoad.regMaskGap;
        opts.cut = optsLoad.cut;
        opts.movAvgWin = optsLoad.movAvgWin;
        opts.minShow1 = optsLoad.minShow1;
        opts.correctTrend = optsLoad.correctTrend;
        opts.propthrmin = optsLoad.propthrmin;
        opts.propthrmax = optsLoad.propthrmax;
        opts.propthrstep = optsLoad.propthrstep;
        opts.compress = optsLoad.compress;
        opts.gapExt = optsLoad.gapExt;
        opts.frameRate = optsLoad.frameRate;
        opts.spatialRes = optsLoad.spatialRes;
        opts.northx = optsLoad.northx;
        opts.northy = optsLoad.northy;
        opts.TPatch = optsLoad.TPatch;
        opts.maxSpaScale = optsLoad.maxSpaScale;
        opts.minSpaScale = optsLoad.minSpaScale;
        
        setappdata(f,'opts',opts);
        
        % adjust interface parameters
        fh = guidata(f);
        fh.registrateCorrect.Value = fh.registrateCorrect.Items{opts.registrateCorrect};
        fh.bleachCorrect.Value = fh.bleachCorrect.Items{opts.bleachCorrect};
        fh.medSmo.Value = num2str(opts.medSmo);
        fh.smoXY.Value = num2str(opts.smoXY);

        fh.thrArScl.Value = num2str(opts.thrARScl);
        fh.minSize.Value = num2str(opts.minSize);
        fh.maxSize.Value = num2str(opts.maxSize);
        fh.circularityThr.Value = num2str(opts.circularityThr);
        fh.minDur.Value = num2str(opts.minDur);
        fh.spaMergeDist.Value = num2str(opts.spaMergeDist);
        
        fh.needTemp.Value = opts.needTemp;
        fh.seedSzRatio.Value = num2str(opts.seedSzRatio);
        fh.sigThr.Value = num2str(opts.sigThr);
        fh.maxDelay.Value = num2str(opts.maxDelay);
%         fh.needRefine.Value = opts.needRefine;
%         fh.needGrow.Value = opts.needGrow;
        
        fh.needSpa.Value = opts.needSpa;
        fh.sourceSzRatio.Value = num2str(opts.sourceSzRatio);
        fh.sourceSensitivity.Value = num2str(opts.sourceSensitivity);
        try
            fh.whetherExtend.Value = opts.whetherExtend;
        end

        fh.detectGlo.Value = opts.detectGlo;
        fh.gloDur.Value = num2str(opts.gloDur);

        fh.ignoreTau.Value = opts.ignoreTau;
        fh.propMetric.Value = opts.propMetric;
        fh.networkFeatures.Value = opts.networkFeatures;
        
        n = round(fh.sldMov.Value);
        ui.mov.updtMovInfo(f,n,opts.sz(4));
    end
end