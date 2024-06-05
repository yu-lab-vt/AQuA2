function outputRegions(fts1, ftTb1, selected1, fts2, ftTb2, selected2, bd, opts, fpath, fname)
    % for each region
    bdcell = bd('cell');
    outputRegions00(fts1, ftTb1, selected1, bdcell, opts, fpath, fname, '_Ch1_region_');
    if(~opts.singleChannel)
        outputRegions00(fts2, ftTb2, selected2, bdcell, opts, fpath, fname, '_Ch2_region_');
    end
end

function outputRegions00(fts, ftTb, selected, bdcell, opts, fpath, fname, fext)
    if isfield(fts,'region') && ~isempty(fts.region) && isfield(fts.region.cell,'memberIdx') && ~isempty(fts.region.cell.memberIdx)
        fpathRegion = [fpath,'\Regions'];
        if ~exist(fpathRegion,'file') && ~isempty(fpathRegion)
            mkdir(fpathRegion);    
        end

        if opts.sz(3) == 1
            if isempty(selected)
                memSel = fts.region.cell.memberIdx;
            else
                memSel = fts.region.cell.memberIdx(selected,:);
            end

            for ii=1:size(memSel,2)
                mem00 = memSel(:,ii);
                Name = 'None';
                if numel(bdcell{ii})>=4
                    Name = bdcell{ii}{4};
                end
                if strcmp(Name,'None')
                   Name = num2str(ii); 
                end
                if(sum(mem00>0)==0)
                    continue;
                end
                cc = ftTb{:,1};
                cc00 = cc(:,mem00>0);
                ftTb00 = table(cc00,'RowNames',ftTb.Row);
                ftb00 = [fpathRegion,filesep,fname,fext,Name,'.xlsx'];
                writetable(ftTb00,ftb00,'WriteVariableNames',0,'WriteRowNames',1);
            end
        end
    end
end