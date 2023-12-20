function res = saveExp(~,~,f,file0,path0,modex)
% saveExp save experiment (and export results)

fts = getappdata(f,'fts1');
if ~exist('modex','var')
    modex = 0;
end
if isempty(fts)
    msgbox('Please save after event detection\n');
    return
end
if ~exist(path0,'file') && ~isempty(path0)
    mkdir(path0);    
end

%% gather results
ff = waitbar(0,'Gathering results ...');

% if do not want to detect again, do not need to save dF
vSave0 = {...  % basic variables for results analysis
    'opts','scl','btSt','ov','bd','datOrg1','evt1','riseLst1','fts1',...
    'gloEvt1','gloRiseLst1','dffMat1','dMat1','dF1','cfuInfo1',...
    'datOrg2','evt2','riseLst2','fts2','gloEvt2','gloRiseLst2','dffMat2','dMat2','dF2','cfuInfo2',...
    'userFeatures','gloEvt1','gloEvt2','ftsGlo1','ftsGlo2','featureTable1','featureTable2'};
vSave = vSave0;

% filter features and curves
ov = getappdata(f,'ov');
ov1 = ov('Events_Red');
xSel1 = ov1.sel;
ov2 = ov('Events_Green');
xSel2 = ov2.sel;
btSt = getappdata(f,'btSt');
opts = getappdata(f,'opts');

evtSelectedList1 = find(xSel1>0);
evtFavList1 = btSt.evtMngrMsk1;
evtSelectedList2 = find(xSel2>0);
evtFavList2 = btSt.evtMngrMsk2;

res = [];
for ii=1:numel(vSave)
    v0 = vSave{ii};
    res.(v0) = getappdata(f,v0);
end
res.evtSelectedList1 = evtSelectedList1;
res.evtFavList1 = evtFavList1;
res.evtSelectedList2 = evtSelectedList2;
res.evtFavList2 = evtFavList2;

% save raw movie with 8 or 16 bits to save space
% res.opts.bitNum = 16;

if opts.BitDepth == 8
    res.datOrg1 = uint8(res.datOrg1*(opts.maxValueDat1 - opts.minValueDat1)+opts.minValueDat1);
    if ~isempty(res.datOrg2)
        res.datOrg2 = uint8(res.datOrg2*(opts.maxValueDat2 - opts.minValueDat2)+opts.minValueDat2);
    end
else
    res.datOrg1 = uint16(res.datOrg1*(opts.maxValueDat1 - opts.minValueDat1)+opts.minValueDat1);
    if ~isempty(res.datOrg2)
        res.datOrg2 = uint16(res.datOrg2*(opts.maxValueDat2 - opts.minValueDat2)+opts.minValueDat2);
    end
end

res.stg.post = 1;
res.stg.detect = 1;

if modex>0
    waitbar(1,ff);
    delete(ff);
    return
end

%% export
fh = guidata(f);
fout = [path0,filesep,file0];
[fpath,fname,ext] = fileparts(fout);
if opts.sz(3)>1
    curSz = size(fh.ims.im1.Data);
    dsSclXY = fh.sldDsXY.Value;
end

if fh.expEvt.Value==1
    waitbar(0.25,ff,'Saving res file...');
    if ~strcmp(fout(end-3:end),'.mat')
        fout = [fout,'.mat'];
    end
    save(fout,'res','-v7.3');
end

% if fh.expEvt2.Value==1
%     waitbar(0.25,ff,'Saving res file...');
%     if ~strcmp(fout(end-3:end),'.mat')
%         fout = [fout,'.mat'];
%     end
%     field = {'datOrg1','datOrg2','dF1','dF2','ov'};
%     res = rmfield(res,field);
%     save(fout,'res','-v7.3');
% end

% export movie
if fh.expMov.Value==1
    waitbar(0.5,ff,'Writing movie ...');
    if opts.sz(3)==1
        ov1 = zeros(opts.sz(1),opts.sz(2),3,opts.sz(4));
        if ~opts.singleChannel
            ov2 = zeros(opts.sz(1),opts.sz(2),3,opts.sz(4));
        end
        for tt=1:opts.sz(4)
            if mod(tt,100)==0
                fprintf('Frame %d\n',tt); 
            end
            datxCol = ui.movStep(f,tt,1);
            ov1(:,:,:,tt) = datxCol{1};
            if ~opts.singleChannel
                ov2(:,:,:,tt) = datxCol{2};
            end
        end
        ui.movStep(f);
        
        if ~opts.singleChannel
            io.writeTiffSeq([fpath,filesep,fname,'_Channel_1.tif'],ov1,8);
            io.writeTiffSeq([fpath,filesep,fname,'_Channel_2.tif'],ov2,8);
        else
            fmov = [fpath,filesep,fname,'.tif'];
            io.writeTiffSeq(fmov,ov1,8);
        end
    else
        fmov = [fpath,filesep,fname,'_Movie',filesep];
        mkdir(fmov);
        for tt = 1:opts.sz(4)
            if mod(tt,100)==0
                fprintf('Frame %d\n',tt); 
            end
            [dat,overLayData,overLayColor] = ui.movStep(f,tt,1);
            curLst = label2idx(overLayData{1});
            rPlane = dat{1};
            gPlane = dat{1};
            bPlane = dat{1};
            for i = 1:numel(curLst)
                pix = curLst{i};
                rPlane(pix) = rPlane(pix) + overLayColor{1}(i+1,1);
                gPlane(pix) = gPlane(pix) + overLayColor{1}(i+1,2);
                bPlane(pix) = bPlane(pix) + overLayColor{1}(i+1,3);
            end
            ov1 = cat(4,rPlane,gPlane,bPlane);
            ov1 = permute(ov1,[1,2,4,3]);
            if ~opts.singleChannel
                curLst = label2idx(overLayData{2});
                rPlane = dat{2};
                gPlane = dat{2};
                bPlane = dat{2};
                for i = 1:numel(curLst)
                    pix = curLst{i};
                    rPlane(pix) = rPlane(pix) + overLayColor{2}(i+1,1);
                    gPlane(pix) = gPlane(pix) + overLayColor{2}(i+1,2);
                    bPlane(pix) = bPlane(pix) + overLayColor{2}(i+1,3);
                end
                ov2 = cat(4,rPlane,gPlane,bPlane);
                ov2 = permute(ov2,[1,2,4,3]);
                io.writeTiffSeq([fmov,'Channel_1_Frame ',num2str(tt),'.tif'],ov1,8);
                io.writeTiffSeq([fmov,'Channel_2_Frame ',num2str(tt),'.tif'],ov2,8);
            else
                io.writeTiffSeq([fmov,'Frame ',num2str(tt),'.tif'],ov1,8);
            end
        end
        ui.movStep(f);
    end
end

if fh.expFt.Value==1
    waitbar(0.75,ff,'Writing feature table ...');
    % export feature table
    ftTb = getappdata(f,'featureTable1');
    if isempty(ftTb)
        ui.detect.getFeatureTable(f);
        ftTb = getappdata(f,'featureTable1');
    end
    cc = ftTb{:,1};

    % all selected events
    cc1 = cc(:,res.evtSelectedList1);
    ftTb1 = table(cc1,'RowNames',ftTb.Row);
    ftb = [fpath,filesep,fname,'_Ch1.csv'];
    writetable(ftTb1,ftb,'WriteVariableNames',0,'WriteRowNames',1);
    
    % for favorite events
    if ~isempty(evtFavList1)
        cc00 = cc(:,evtFavList1);
        ftTb00 = table(cc00,'RowNames',ftTb.Row);
        ftb00 = [fpath,filesep,fname,'_Ch1_favorite.xlsx'];
        writetable(ftTb00,ftb00,'WriteVariableNames',0,'WriteRowNames',1);
    end

    if(~opts.singleChannel)
        ftTb = getappdata(f,'featureTable2');
        if isempty(ftTb)
            ui.detect.getFeatureTable(f);
            ftTb = getappdata(f,'featureTable2');
        end
        cc = ftTb{:,1};

        % all selected events
        cc1 = cc(:,res.evtSelectedList2);
        ftTb1 = table(cc1,'RowNames',ftTb.Row);
        ftb = [fpath,filesep,fname,'_Ch2.csv'];
        writetable(ftTb1,ftb,'WriteVariableNames',0,'WriteRowNames',1);
        
            % for favorite events
        if ~isempty(evtFavList2)
            cc00 = cc(:,evtFavList2);
            ftTb00 = table(cc00,'RowNames',ftTb.Row);
            ftb00 = [fpath,filesep,fname,'_Ch2_favorite.xlsx'];
            writetable(ftTb00,ftb00,'WriteVariableNames',0,'WriteRowNames',1);
        end
    end
    
    %% curves
    dffAlignedMat1 = getappdata(f,'dffAlignedMat1');
    nEvt = size(dffAlignedMat1,1);
    rowName = cell(nEvt,1);
    risetime10 = zeros(nEvt,1);
    ftsLst1 = getappdata(f,'fts1');
    for k = 1:nEvt
       risetime10(k) = ftsLst1.curve.dff1Begin(k);
    end
    mat = [nan(nEvt,1),risetime10,dffAlignedMat1];
    mat = [nan(1,113);mat];
    mat = (num2cell(mat));
    for k = 1:nEvt
        mat{k+1,1} = ['Event ',num2str(k)];
    end
    mat{1,1} = 'Event ID';
    mat{1,2} = '10% Rise time';
    for k = 1:111
        if k>11
            mat{1,k+2} = ['df/f0 at +',num2str(k-11)];
        else
            mat{1,k+2} = ['df/f0 at ',num2str(k-11)];
        end
    end
    mat = table(mat);
    writetable(mat,[fpath,filesep,fname,'_Ch1_curves.xlsx'],'WriteVariableNames',0,'WriteRowNames',0);
    if(~opts.singleChannel)
        dffAlignedMat2 = getappdata(f,'dffAlignedMat2');
        nEvt = size(dffAlignedMat2,1);
        risetime10 = zeros(nEvt,1);
        ftsLst2 = getappdata(f,'fts2');
        for k = 1:nEvt
           risetime10(k) = ftsLst2.curve.dff1Begin(k);
        end
        mat = [nan(nEvt,1),risetime10,dffAlignedMat2];
        mat = [nan(1,113);mat];
        mat = (num2cell(mat));
        for k = 1:nEvt
            mat{k+1,1} = ['Event ',num2str(k)];
        end
        mat{1,1} = 'Event ID';
        mat{1,2} = '10% Rise time';
        for k = 1:110
            if k>11
                mat{1,k+2} = ['df/f0 at +',num2str(k-11)];
            else
                mat{1,k+2} = ['df/f0 at ',num2str(k-11)];
            end
        end
        mat = table(mat);
        writetable(mat,[fpath,filesep,fname,'_Ch2_curves.xlsx'],'WriteVariableNames',0,'WriteRowNames',0);
    end
    
    bd = getappdata(f,'bd');
    
    % for each region
    if isfield(fts,'region') && ~isempty(fts.region) && isfield(fts.region.cell,'memberIdx') && ~isempty(fts.region.cell.memberIdx)
        bdcell = bd('cell');
        fpathRegion = [fpath,'\Regions'];
        if ~exist(fpathRegion,'file') && ~isempty(fpathRegion)
            mkdir(fpathRegion);    
        end

        if opts.sz(3) == 1
            memSel = fts.region.cell.memberIdx(res.evtSelectedList1,:);
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
                cc00 = cc(:,mem00>0);
                ftTb00 = table(cc00,'RowNames',ftTb.Row);
                ftb00 = [fpathRegion,filesep,fname,'ch1_region_',Name,'.xlsx'];
                writetable(ftTb00,ftb00,'WriteVariableNames',0,'WriteRowNames',1);
            end
            
            if(~opts.singleChannel)
                fts = getappdata(f,'fts2');
                memSel = fts.region.cell.memberIdx(res.evtSelectedList2,:);
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
                    cc00 = cc(:,mem00>0);
                    ftTb00 = table(cc00,'RowNames',ftTb.Row);
                    ftb00 = [fpathRegion,filesep,fname,'ch2_region_',Name,'.xlsx'];
                    writetable(ftTb00,ftb00,'WriteVariableNames',0,'WriteRowNames',1);
                end
            end
        end
    end

    % region and landmark map
    if opts.sz(3)==1
        f00 = figure('Visible','off');
        dat = getappdata(f,'datOrg1');
        dat = mean(dat,4);
        dat = dat/max(dat(:));
        Low_High = stretchlim(dat(:),0.001);
        dat = (dat-Low_High(1)) * (Low_High(2)-Low_High(1));
        dat(dat<0) = 0;
        dat(dat>1) = 1;
        axNow = axes(f00);
        image(axNow,'CData',flipud(dat),'CDataMapping','scaled');
        axNow.XTick = [];
        axNow.YTick = [];
        axNow.XLim = [0.5,size(dat,2)+0.5];
        axNow.YLim = [0.5,size(dat,1)+0.5];
        axNow.DataAspectRatio = [1 1 1];
        colormap gray
        ui.mov.addPatchLineText(f,axNow,0,1)
        % saveas(f00,[fpath,filesep,fname,'_landmark.fig']);
        saveas(f00,[fpath,filesep,fname,'_landmark.png'],'png');
        delete(f00);
    end
    

    % rising maps
    if opts.sz(3)==1
        riseLst1 = getappdata(f,'riseLst1');
        if ~isempty(evtFavList1) && ~isempty(riseLst1)
            f00 = figure('Visible','off');
            axNow = axes(f00);
            fpathRising = [fpath,filesep,'risingMaps_CH1'];
            if ~exist(fpathRising,'file')
                mkdir(fpathRising);
            end

            for ii=1:numel(evtFavList1)
                rr = riseLst1{evtFavList1(ii)};
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
                saveas(f00,[fpathRising,filesep,num2str(evtFavList1(ii)),'.png'],'png');
            end
        end
    
        if(~opts.singleChannel)
            riseLst2 = getappdata(f,'riseLst2');
            if ~isempty(evtFavList2) && ~isempty(riseLst2)
                f00 = figure('Visible','off');
                axNow = axes(f00);
                fpathRising = [fpath,filesep,'risingMaps_CH2'];
                if ~exist(fpathRising,'file')
                    mkdir(fpathRising);
                end
                for ii=1:numel(evtFavList2)
                    rr = riseLst2{evtFavList2(ii)};
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
                    saveas(f00,[fpathRising,filesep,num2str(evtFavList2(ii)),'.png'],'png');
                end
            end
        end
    else
        riseLst1 = getappdata(f,'riseLst1');
        if ~isempty(evtFavList1)
            fpathRising = [fpath,filesep,'risingMaps_CH1'];
            if ~exist(fpathRising,'file')
                mkdir(fpathRising);
            end

            jm = jet(1000);
            for ii=1:numel(evtFavList1)
                rr = riseLst1{evtFavList1(ii)};
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
                io.writeTiffSeq([fpathRising,filesep,num2str(evtFavList1(ii)),'.tiff'],mapOut,8);
            end
        end
    end
end

delete(ff);

end







