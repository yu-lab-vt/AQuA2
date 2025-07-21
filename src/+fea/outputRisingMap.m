function outputRisingMap(curSz, dsSclXY, riseLst1, evtFavList1, riseLst2, evtFavList2, opts, fpath, fR)  % bug fixed 07/17/2025
    
    outputRisingMap00(curSz, dsSclXY, riseLst1, evtFavList1, opts, fpath, [fR,'_Ch1']);
    if (~opts.singleChannel)
        outputRisingMap00(curSz, dsSclXY, riseLst2, evtFavList2, opts, fpath, [fR,'_Ch2']);
    end
end
function outputRisingMap00(curSz, dsSclXY, riseLst, selected, opts, fpath, fext)
    if opts.sz(3)==1
        if ~isempty(selected) && ~isempty(riseLst)
            f00 = figure('Visible','off');
            axNow = axes(f00);
            fpathRising = [fpath,filesep,fext];
            if ~exist(fpathRising,'file')
                mkdir(fpathRising);
            end

            for ii=1:numel(selected)
                rr = riseLst{selected(ii)};
                riseMap = rr.dlyMap50;
                rs = riseMap(~isnan(riseMap(:)));
                maxRs = ceil(max(rs));
                minRs = floor(min(rs));
                h = imagesc(axNow,riseMap);
                colormap(axNow,jet);
                colorbar(axNow);
                set(h, 'AlphaData', ~isnan(riseMap));
                try
                    caxis(axNow,[minRs,maxRs]);
                end
                xx = axNow.XTickLabel;
                for jj=1:numel(xx)
                    xx{jj} = num2str(str2double(xx{jj})+min(rr.rgw)-1);
                end
                axNow.XTickLabel = xx;
                xx = axNow.YTickLabel;
                for jj=1:numel(xx)
                    xx{jj} = num2str(str2double(xx{jj})+min(rr.rgw)-1);
                end
                axNow.YTickLabel = xx;
                axNow.DataAspectRatio = [1 1 1];
                saveas(f00,[fpathRising,filesep,num2str(selected(ii)),'.png'],'png');
            end
        end
    else
        if ~isempty(selected)
            fpathRising = [fpath,filesep,fext];
            if ~exist(fpathRising,'file')
                mkdir(fpathRising);
            end

            jm = jet(1000);
            for ii=1:numel(selected)
                rr = riseLst{selected(ii)};
                riseMap = nan(opts.sz(1:3));
                riseMap(rr.rgh,rr.rgw,rr.rgl) = rr.dlyMap50;
                maxRs = ceil(max(riseMap(:)));
                minRs = floor(min(riseMap(:)));
                riseMap = round(riseMap);
                riseMap(isnan(riseMap)) = 0;
                dlyLst = label2idx(riseMap);
                rPlane = ones(curSz);
                gPlane = ones(curSz);
                bPlane = ones(curSz);
                szCluster = cellfun(@numel,dlyLst);
                dlyLst = dlyLst(szCluster>0);
                for i = 1:numel(dlyLst)
                    pix = dlyLst{i};
                    delay = riseMap(pix(1));
                    [ih,iw,il] = ind2sub(opts.sz(1:3),pix);
                    if maxRs>minRs
                        rId = round((delay-minRs)/(maxRs-minRs)*999+1);
                    else
                        rId = 500;
                    end
                    rId = max(min(rId,1000),1);
                    pix = sub2ind(curSz,ceil(ih/dsSclXY),ceil(iw/dsSclXY),il);
                    rPlane(pix) = jm(rId,1);
                    gPlane(pix) = jm(rId,2);
                    bPlane(pix) = jm(rId,3);
                end
                mapOut = cat(4,rPlane,gPlane,bPlane);
                mapOut = permute(mapOut,[1,2,4,3]);
                io.writeTiffSeq([fpathRising,filesep,num2str(selected(ii)),'.tiff'],mapOut,8);
            end
        end
    end
end