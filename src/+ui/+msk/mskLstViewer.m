function mskLstViewer(~,evtDat,f,op)
    % op: refresh, remove, select, or open.
    
    fh = guidata(f);
    tb = fh.mskTable;
    
    bd = getappdata(f,'bd');
    bdMsk = bd('maskLst');
    stg = 0;
    
    if strcmp(op,'refresh') || strcmp(op,'open')
        nMsk = numel(bdMsk);
        dat = cell(nMsk,3);
        for ii=1:nMsk
            rr = bdMsk{ii};
            dat{ii,1} = false;
            dat{ii,2} = rr.name;
            dat{ii,3} = rr.type;
        end
        dat{nMsk,1} = true;
        tb.Data = dat;
        rr = bdMsk{end};
        
        if strcmp(op, 'open')
            stg = 1; 
        end
    end
    
    if strcmp(op,'select')
        evtInd = evtDat.Indices;
        if isempty(evtInd)
            return
        end
        idx = evtInd(1,1);
        dat = tb.Data;
        for ii=1:size(dat,1)
            dat{ii,1} = false;
        end
        dat{idx,1} = true;
        tb.Data = dat;
        rr = bdMsk{idx};
        stg = 1;
    end
    
    if strcmp(op,'remove')
        dat = tb.Data;
        if isempty(dat)
            return
        end
        if size(dat,1)==1
            dat = zeros(0,3);
            tb.Data = dat;
            bd('maskLst') = [];
            im = fh.imsMsk;
            d0 = ones(100,100,3);
            im.CData = d0;
            fh.imgMsk.XLim = [1 100];
            fh.imgMsk.YLim = [1 100];
            setappdata(f,'bd',bd);
            return
        else
            idxLog = cell2mat(dat(:,1));
            delIdx = find(idxLog, 1);
            if isempty(delIdx)
                delIdx = 1;
            end
            
            dat = dat(~idxLog,:);
            
            % Update: select the nearest remaining layer after removal.
            newIdx = min(delIdx, size(dat,1));
            dat{newIdx,1} = true;
            
            tb.Data = dat;
            bdMsk = bdMsk(~idxLog);
            rr = bdMsk{newIdx};
            bd('maskLst') = bdMsk;
            setappdata(f,'bd',bd);
            
            % Update: preserve the selected mask without recalculating it.
            stg = 1; 
        end
    end
    
    ui.msk.updtMskSld([],[],f,rr);
    ui.msk.viewImgMsk([],[],f,stg);  % update image 
end
