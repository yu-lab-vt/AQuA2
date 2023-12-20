function getFeatureTable(f)

bd = getappdata(f,'bd');
opts = getappdata(f,'opts');
if bd.isKey('landmk')
    bd1 = bd('landmk');
    if opts.sz(3)==1
        lmkLst = cell(numel(bd1),1);
        for ii=1:numel(bd1)
            lmkLst{ii} = bd1{ii}{1};
        end
    else
        lmkLst = [];
    end
else
    lmkLst = [];
end

% show in event manager and for exporting
fts1 = getappdata(f,'fts1');
evtLst1 = getappdata(f, 'evt1');
featureTable1 = getFeatureTable00(fts1,evtLst1,lmkLst,f);
if(~opts.singleChannel)
    fts2 = getappdata(f,'fts2');
    evtLst2 = getappdata(f, 'evt2');
    featureTable2 = getFeatureTable00(fts2,evtLst2,lmkLst,f);
else
    featureTable2 = [];
end
setappdata(f,'featureTable1',featureTable1);
setappdata(f,'featureTable2',featureTable2);

end
function featureTable = getFeatureTable00(fts,evtLst,lmkLst,f)
    tb = getappdata(f,'userFeatures');

    if isempty(evtLst)
        featureTable = table(nan(0,1));
        setappdata(f,'featureTable',featureTable);
        return
    end

    nEvt = numel(fts.basic.area);
    nFt = numel(tb.Name);
    ftsTb = cell(nFt,nEvt);
    ftsName = cell(nFt,1);
    ftsCnt = 1;
    dixx = fts.notes.propDirectionOrder;
    valid = false(100,1);

    for ii=1:nFt
        cmdSel0 = tb.Script{ii};
        ftsName0 = tb.Name{ii};
        % if find landmark or direction
        if ~isempty(strfind(cmdSel0,'xxLmk')) %#ok<STREMP>
            for xxLmk=1:numel(lmkLst)
                try
                    eval([cmdSel0,';']);
                    valid(ftsCnt) = true;
                catch
                    fprintf('Feature "%s" not selected\n',ftsName0)
                    x = nan(nEvt,1);
                end
                ftsTb(ftsCnt,:) = num2cell(reshape(x,1,[]));
                ftsName1 = [ftsName0,' - landmark ',num2str(xxLmk)];
            end
        elseif ~isempty(strfind(cmdSel0,'xxDi')) %#ok<STREMP>
            for xxDi=1:numel(dixx)
                try
                    eval([cmdSel0,';']);
                    ftsTb(ftsCnt,:) = num2cell(reshape(x,1,[]));
                    valid(ftsCnt) = true;
                catch
                    fprintf('Feature "%s" not selected\n',ftsName0)
%                     ftsTb(ftsCnt,:) = nan;
                end            
                ftsName1 = [ftsName0,' - ',dixx{xxDi}];
            end
        else
            try
                eval([cmdSel0,';']);
                if(iscell(x))
                    ftsTb(ftsCnt,:) = x;
                else
                    ftsTb(ftsCnt,:) = num2cell(reshape(x,1,[]));            
                end
                valid(ftsCnt) = true;
            catch
                fprintf('Feature "%s" not selected\n',ftsName0)
                ftsTb(ftsCnt,:) = num2cell(nan(1,nEvt));
            end
            ftsName1 = ftsName0;
        end
        ftsName{ftsCnt} = ftsName1;
        ftsCnt = ftsCnt + 1;
    end
    valid = valid(1:ftsCnt-1);
    ftsTb = ftsTb(valid,:); ftsName = ftsName(valid);
    featureTable = table(ftsTb,'RowNames',ftsName);
end

