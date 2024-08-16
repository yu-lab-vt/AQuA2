function featureTable = getFeatureTable00(fts,lmkLst,f)
    if exist('f','var')&&~isempty(f)
        tb = getappdata(f,'userFeatures');
    else
        tb = readtable('userFeatures.csv','Delimiter',',');
        if isfield(fts.basic,'peri')
            tb = readtable('userFeatures2.csv','Delimiter',',');
        else
            tb = readtable('userFeatures.csv','Delimiter',',');
        end
    end

    nFt = numel(tb.Name);
    ftsName = cell(nFt,1);

    if isempty(fts)
        featureTable = table(cell(nFt,0),'RowNames',tb.Name);
        return;
    end
    nEvt = numel(fts.basic.area);
    dixx = fts.notes.propDirectionOrder;

    ftsTb = cell(nFt,nEvt);
    ftsCnt = 1;
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

