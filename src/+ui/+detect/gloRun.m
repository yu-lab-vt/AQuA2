function gloRun(~,~,f)
% z scores and filtering

fh = guidata(f);
opts = getappdata(f,'opts');
opts.detectGlo = fh.detectGlo.Value;
opts.gloDur = str2double(fh.gloDur.Value);
setappdata(f,'opts',opts);
opts.minDur = opts.gloDur;
ff = waitbar(0,'Detecting global events...');
if(opts.detectGlo)
    sz = opts.sz;
    evtSpatialMask = true(sz(1:3));
    bd = getappdata(f,'bd');
    if bd.isKey('cell')
        bd0 = bd('cell');
        if sz(3)==1
            if numel(bd0) > 0
                evtSpatialMask = false(sz(1:3));
                for ii=1:numel(bd0)
                    p0 = bd0{ii}{2};
                    evtSpatialMask(p0) = true;
                end
            end
        else
            evtSpatialMask = bd0;
        end
    end

    %% channel 1
    dF1 = getappdata(f,'dF1');
    evtLocalLst1 = getappdata(f,'evt1'); 
    
    waitbar(0,ff,'Remove detected local events...');
    fprintf('Remove detected local events ...\n')
    dF_glo1 = glo.removeDetected(dF1,evtLocalLst1);
    clear dF1;
    % active region
    waitbar(0.1,ff,'Global active region...');
    [gloArLst1] = act.acDetect(dF_glo1,opts,evtSpatialMask,1,[]);  % foreground and seed detection
    
    % temporal segmentation
    if(fh.needTemp.Value)
        waitbar(0.6,ff,'Temporal segmentation for global signal...');
        datOrg1 = getappdata(f,'datOrg1');
        [gloSeLst1,gloSubEvtLst1,gloSeLabel1,gloMajorInfo1,opts,~,~,~] = se.seDetection(dF_glo1,datOrg1,gloArLst1,opts,[]);
    else
        gloSeLst1 = gloArLst1; 
        gloSubEvtLst1 = gloArLst1; 
        gloSeLabel1 = 1:numel(gloSeLst1);
        gloMajorInfo1 = se.getMajority_Ac(gloSeLst1,gloSeLst1,dF_glo1,opts);
    end

    clear datOrg1;
    if(fh.needSpa.Value)
        % spatial segmentation
        waitbar(0.9,ff,'Spatial segmentation for global signal...');
        [gloRiseLst1,gloDatR1,gloEvt1,~] = evt.se2evtTop(dF_glo1,gloSeLst1,gloSubEvtLst1,gloSeLabel1,gloMajorInfo1,opts,[]);
    else
        gloDatR1 = [];
        gloEvt1 = gloSeLst1;
        gloRiseLst1 = [];
    end
    clear dF_glo1;
    setappdata(f,'gloEvt1',gloEvt1);
    setappdata(f,'gloRiseLst1',gloRiseLst1);
    
    %% channel 2
    if(~opts.singleChannel)
        dF2 = getappdata(f,'dF2');
        evtLocalLst2 = getappdata(f,'evt2'); 
        
        waitbar(0,ff,'Remove detected local events CH2...');
        fprintf('Remove detected local events ...\n')
        dF_glo2 = glo.removeDetected(dF2,evtLocalLst2);
        clear dF2;
        % active region
        waitbar(0.1,ff,'Global active region...');
        [gloArLst2] = act.acDetect(dF_glo2,opts,evtSpatialMask,1,[]);  % foreground and seed detection
        
        % temporal segmentation
        if(fh.needTemp.Value)
            waitbar(0.6,ff,'Temporal segmentation for global signal...');
            datOrg2 = getappdata(f,'datOrg2');
            [gloSeLst2,gloSubEvtLst2,gloSeLabel2,gloMajorInfo2,opts,~,~,~] = se.seDetection(dF_glo2,datOrg2,gloArLst2,opts,[]);
        else
            gloSeLst2 = gloArLst2; 
            gloSubEvtLst2 = gloArLst2; 
            gloSeLabel2 = 1:numel(gloSeLst2);
            gloMajorInfo2 = se.getMajority_Ac(gloSeLst2,gloSeLst2,dF_glo2,opts);
        end
    
        clear datOrg2;
        if(fh.needSpa.Value)
            % spatial segmentation
            waitbar(0.9,ff,'Spatial segmentation for global signal...');
            [gloRiseLst2,gloDatR2,gloEvt2,~] = evt.se2evtTop(dF_glo2,gloSeLst2,gloSubEvtLst2,gloSeLabel2,gloMajorInfo2,opts,[]);
        else
            gloDatR2 = [];
            gloEvt2 = gloSeLst2;
            gloRiseLst2 = [];
        end
        clear dF_glo2;
        setappdata(f,'gloEvt2',gloEvt2);
        setappdata(f,'gloRiseLst2',gloRiseLst2);
    else
        gloEvt2 = [];gloDatR2 = []; gloRiseLst2 = [];
    end

    waitbar(1,ff);
    fprintf('Done\n')
    ui.detect.postRun([],[],f,gloEvt1,gloEvt2,gloDatR1,gloDatR2,'Global Events');
    fh.nEvtName.Text = 'nEvt|nGlo';
    if(~opts.singleChannel)
        fh.nEvt.Text = [num2str(numel(gloEvt1)),' | ',num2str(numel(gloEvt2))];
    else
        fh.nEvt.Text = [num2str(numel(evtLocalLst1)),' | ',num2str(numel(gloEvt1))];
    end
end
delete(ff);

end