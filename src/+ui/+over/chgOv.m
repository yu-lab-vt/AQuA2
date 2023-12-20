function chgOv(~,~,f,op)
% overlay related functions

fh = guidata(f);
opts = getappdata(f,'opts');

% read overlay features
if op==0
    tb = readtable('userFeatures.csv','Delimiter',',');
    setappdata(f,'userFeatures',tb);
    fh.overlayFeature.Items = tb.Name(2:end);
    fprintf('Reading done.\n');
    return
end

% enable or disable feature overlay
if op==1
    ovName = fh.overlayDat.Value;
    if strcmp(ovName,'Events')
        xxx = 'on';
    else        
        xxx = 'off';
    end
    fh.overlayFeature.Enable = xxx;
    fh.overlayColor.Enable = xxx;
    fh.overlayTrans.Enable = xxx;
    fh.overlayScale.Enable = xxx;
    fh.overlayPropDi.Enable = xxx;
    fh.overlayLmk.Enable = xxx;
%     fh.sldBriOv.Enable = xxx;
    fh.updtFeature1.Enable = xxx;
    return
end

% colorbar setting
if strcmp(fh.pMovColMap.Visible,'on') && strcmp(fh.overlayColor.Value,'Random')
    fh.pMovColMap.Visible = 'off';
elseif strcmp(fh.pMovColMap.Visible,'off') && ~strcmp(fh.overlayColor.Value,'Random')
    fh.pMovColMap.Visible = 'on';
end


% calcuate overlay
ovSel = fh.overlayDat.Value;
btSt = getappdata(f,'btSt');
btSt.overlayDatSel = ovSel;
btSt.overlayColorSel = 'Random';

% update color code for events
if (strcmp(ovSel,'Events') && strcmp(fh.updtFeature1.Enable, 'on'))    
    ovFea = fh.overlayFeature.Value;
    ovCol = fh.overlayColor.Value;    
    
    btSt.overlayFeatureSel = ovFea;
    btSt.overlayColorSel = ovCol;
        
    xxTrans = 'None';%fh.overlayTrans.Value;  % transform
    xxScale = 'None';%fh.overlayScale.Value;  % scale
    xxDi = 'None';%fh.overlayPropDi.Value;  % direction
    xxLmk = 'None';%str2double(fh.overlayLmk.Value);  % landmark
        
    %% channel 1
    fts = getappdata(f,'fts1');
    tb = getappdata(f,'userFeatures');
    xSel = cellfun(@(x) strcmp(x,ovFea), tb.Name);
    cmdSel = tb.Script{xSel};
    if isfield(fts,'locAbs')
        nEvt = numel(fts.locAbs);
    else
        nEvt = numel(getappdata(f,'evt1'));
    end
    % change overlay value according to user input
    try
        cVal = ui.over.getVal(fts,cmdSel,xxTrans,xxScale,xxDi,xxLmk);
    catch
        msgbox('Invalid script');
        return
    end
    
    if sum(~isnan(cVal))==0
        msgbox('This feature is not used');
        return
    end
    
    if sum(~isinf(cVal))==0
        cVal = zeros(numel(cVal),1);
    end
    
    cVal(isinf(cVal) & cVal>0) = max(cVal(~isinf(cVal)));
    cVal(isinf(cVal) & cVal<0) = min(cVal(~isinf(cVal)));
    
    % update overlay color
    [col0,cMap0] = ui.over.getColorCode(f,nEvt,ovCol,cVal,1);
    btSt.mapNow = cMap0;
    ov = getappdata(f,'ov');
    ov0 = ov('Events_Red');
    ov0.col = col0;
    ov0.colVal = cVal;
    ov('Events_Red') = ov0;
    
    %% channel 2
    if(~opts.singleChannel)
        fts = getappdata(f,'fts2');
        tb = getappdata(f,'userFeatures');
        xSel = cellfun(@(x) strcmp(x,ovFea), tb.Name);
        cmdSel = tb.Script{xSel};
        if isfield(fts,'locAbs')
            nEvt = numel(fts.locAbs);
        else
            nEvt = numel(fts.basic.area);
        end
        % change overlay value according to user input
        try
            cVal = ui.over.getVal(fts,cmdSel,xxTrans,xxScale,xxDi,xxLmk);
        catch
            msgbox('Invalid script');
            return
        end

        if sum(~isnan(cVal))==0
            msgbox('This feature is not used');
            return
        end

        if sum(~isinf(cVal))==0
            cVal = zeros(numel(cVal),1);
        end

        cVal(isinf(cVal) & cVal>0) = max(cVal(~isinf(cVal)));
        cVal(isinf(cVal) & cVal<0) = min(cVal(~isinf(cVal)));

        % update overlay color
        [col0,cMap0] = ui.over.getColorCode(f,nEvt,ovCol,cVal,2);
        btSt.mapNow = cMap0;
        ov = getappdata(f,'ov');
        ov0 = ov('Events_Green');
        ov0.col = col0;
        ov0.colVal = cVal;
        ov('Events_Green') = ov0;
    end
    setappdata(f,'ov',ov);
    
    % update min, max and brightness slider
    scl = getappdata(f,'scl');
    scl.minOv = min(cVal);
    scl.maxOv = max(cVal);
    setappdata(f,'scl',scl);
else
    % re-shuffle color code in other cases
    if ~strcmp(ovSel,'None')
        ov = getappdata(f,'ov');
        ov0 = ov([ovSel,'_Red']);
        nEvt = numel(ov0.colVal);
        col0 = ui.over.getColorCode(f,nEvt,'Random',[],1);
        ov0.col = col0;
        ov(ovSel) = ov0;
        
        ov0 = ov([ovSel,'_Green']);
        nEvt = numel(ov0.colVal);
        col0 = ui.over.getColorCode(f,nEvt,'Random',[],1);
        ov0.col = col0;
        ov(ovSel) = ov0;
        setappdata(f,'ov',ov);
    end
end

setappdata(f,'btSt',btSt);

% update color map
ui.over.adjMov([],[],f,1);

% show movie with overlay
ui.movStep(f);
end







