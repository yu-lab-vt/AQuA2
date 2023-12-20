function prepInitUI(f,fh,opts,scl,~,stg,op)
% ----------- Modified by Xuelong Mi, 11/09/2022 -----------    
    % layer panel
    fh.sldMin.Limits = [scl.min scl.max];
    fh.sldMin.Value = scl.min;
    
    fh.sldMax.Limits = [scl.min scl.max];
    fh.sldMax.Value = scl.max;
    
    fh.sldBri1.Limits = [0,10];
    fh.sldBri1.Value = scl.bri1;
    
    if ~opts.singleChannel
        fh.sldBri2.Limits = [0,10];
        fh.sldBri2.Value = scl.bri1;
    end
    
    fh.sldBriL.Limits = [0,10];
    fh.sldBriL.Value = scl.briL;
    
    fh.sldBriR.Limits = [0,10];
    fh.sldBriR.Value = scl.briR;
    
    fh.sldBriOv.Limits = [0,1];
    fh.sldBriOv.Value = scl.briOv;

    if opts.sz(3)>1
        fh.xPos.Limits = [1,opts.sz(2)];
        fh.xPos.Value = (1+opts.sz(2))/2;
    
        fh.yPos.Limits = [1,opts.sz(1)];
        fh.yPos.Value = (1+opts.sz(1))/2;

        fh.zPos.Limits = [1,opts.sz(3)];
        fh.zPos.Value = (1 + opts.sz(3))/2;
    end

    T = opts.sz(4);
%     gap = round(T/100);
    fh.curve.XLim = [0,T+1];
    xticks(fh.curve,'auto');
%     fh.curve.xTick = 0:opts.sz(3)
    
    % data panel
    fh.sldMov.Limits = [1,opts.sz(4)];
    fh.sldMov.Value = 1;

    % data panel
    fh.sldActThr.Limits = [0,max(10,opts.thrARScl)];
    fh.sldActThr.Value = opts.thrARScl;
    
    % detection parameters
    if op==0
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
        fh.needRefine.Value = opts.needRefine;
        fh.needGrow.Value = opts.needGrow;
        
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
    end
    
    try
        % update overlay menu
        ui.over.updateOvFtMenu([],[],f);
        
        % User defined features
        ui.over.chgOv([],[],f,0);
        ui.over.chgOv([],[],f,1);
        ui.over.chgOv([],[],f,2);
        ui.evt.evtMngrRefresh([],[],f);
    catch
    end
    
    % resize GUI
    fh.Card2.Visible = 'off';
    fh.Card3.Visible = 'on';
    f.KeyReleaseFcn = {@ui.mov.findKeyPress};
    f.Position = getappdata(f,'guiMainSz');
    
    dbgx = getappdata(f,'dbg');
    if isempty(dbgx); dbgx=0; end        
    
    % UI visibility according to steps
    if stg.detect==0  % not started yet
        fh.deOutNext.Enable = 'off';
        fh.pFilter.Visible = 'off';
        fh.pExport.Visible = 'off';
        fh.pEvtMngr.Visible = 'off';
        fh.pSys.Visible = 'off';
        fh.deOutTab.SelectedTab  = fh.deOutTab.Children(1);
        fh.deOutBack.Visible = 'off';
    else  % finished
        ui.detect.filterInit([],[],f);
        fh.deOutBack.Enable = 'off';
        fh.deOutTab.SelectedTab = fh.deOutTab.Children(end);
        fh.deOutNext.Enable = 'on';
    end

    
    % show movie
    ui.movStep(f,1,[],1);
    
end





