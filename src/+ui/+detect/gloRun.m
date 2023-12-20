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
    [arLst1] = act.acDetect(dF_glo1,opts,evtSpatialMask,1,[]);  % foreground and seed detection
    
    % temporal segmentation
    if(fh.needTemp.Value)
        waitbar(0.6,ff,'Temporal segmentation for global signal...');
        datOrg1 = getappdata(f,'datOrg1');
        [seLst1,subEvtLst1,seLabel1,majorInfo1,opts,~,~,~] = se.seDetection(dF_glo1,datOrg1,arLst1,opts,[]);
        clear datOrg1;
        if(fh.needSpa.Value)
            % spatial segmentation
            waitbar(0.9,ff,'Spatial segmentation for global signal...');
            [riseLst1,datR1,evtLst1,~] = evt.se2evtTop(dF_glo1,seLst1,subEvtLst1,seLabel1,majorInfo1,opts,[]);
        else
            evtLst1 = seLst1; riseLst1 = []; datR1 = [];
        end
    else
        evtLst1 = arLst1; riseLst1 = []; datR1 = [];
    end
    clear dF_glo1;
    setappdata(f,'gloEvt1',evtLst1);
    setappdata(f,'gloRiseLst1',riseLst1);
    
    %% channel 2
    if(~opts.singleChannel)
        dF2 = getappdata(f,'dF2');
        evtLocalLst2 = getappdata(f,'evt2'); 
        
        waitbar(0,ff,'Remove detected local events CH2...');
        fprintf('Remove detected local events ...\n')
        dF_glo2 = glo.removeDetected(dF2,evtLocalLst2);
        clear dF2;
        % active region
        waitbar(0.1,ff,'Global active region CH2...');
        [arLst2] = act.acDetect(dF_glo2,opts,evtSpatialMask,2,[]);  % foreground and seed detection

        % temporal segmentation
        if(fh.needTemp.Value)
            waitbar(0.6,ff,'Temporal segmentation for global signal CH2...');
            datOrg2 = getappdata(f,'datOrg2');
            [seLst2,subEvtLst2,seLabel2,majorInfo2,opts,~,~,~] = se.seDetection(dF_glo2,datOrg2,arLst2,opts,[]);
            clear datOrg2;
            if(fh.needSpa.Value)
                % spatial segmentation
                waitbar(0.9,ff,'Spatial segmentation for global signal CH2...');
                [riseLst2,datR2,evtLst2,~] = evt.se2evtTop(dF_glo2,seLst2,subEvtLst2,seLabel2,majorInfo2,opts,[]);
            else
                evtLst2 = seLst2; riseLst2 = []; datR2 = [];
            end
        else
            evtLst2 = arLst2; riseLst2 = []; datR2 = [];
        end
        setappdata(f,'gloEvt2',evtLst2);
        setappdata(f,'gloRiseLst2',riseLst2);
    else
        evtLst2 = [];datR2 = [];
    end
    waitbar(1,ff);
    fprintf('Done\n')
    ui.detect.postRun([],[],f,evtLst1,evtLst2,datR1,datR2,'Global Events');
    fh.nEvtName.Text = 'nEvt|nGlo';
    if(~opts.singleChannel)
        fh.nEvt.Text = [num2str(numel(evtLst1)),' | ',num2str(numel(evtLst2))];
    else
        fh.nEvt.Text = [num2str(numel(evtLocalLst1)),' | ',num2str(numel(evtLst1))];
    end
end
delete(ff);

end