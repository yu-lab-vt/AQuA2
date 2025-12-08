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
    'opts', 'cfuOpts','scl','btSt','ov','bd','datOrg1','evt1','riseLst1','fts1',...
    'gloEvt1','gloRiseLst1','dffMat1','dMat1','dF1','cfuInfo1',...
    'datOrg2','evt2','riseLst2','fts2','gloEvt2','gloRiseLst2','dffMat2','dMat2','dF2','cfuInfo2',...
    'userFeatures','gloEvt1','gloEvt2','ftsGlo1','ftsGlo2','featureTable1','featureTable2','cfuRelation','cfuGroupInfo'};
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
curSz = [];
dsSclXY = [];
if opts.sz(3)>1
    curSz = size(fh.ims.im1.Data);
    dsSclXY = fh.sldDsXY.Value;
end

tic

if fh.expEvt.Value==1
    waitbar(0.25,ff,'Saving res file, may take a while...');
    if ~strcmp(fout(end-3:end),'.mat')
        fout = [fout,'.mat'];
    end
    % Use this line if space is stirctly limited, at the cost of time
    % save(fout,'res','-v7.3');    
    save(fout,'res','-v7.3','-nocompression');
end

toc

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

    %  for global events
    if(opts.detectGlo)
        writetable(getappdata(f,'featureTableGlo1'),[fpath,filesep,fname,'_Glo_Ch1.xlsx'],'WriteVariableNames',0,'WriteRowNames',1);
    end

    if(~opts.singleChannel)
        ftTb = getappdata(f,'featureTable2');
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

        %  for global events
        if(opts.detectGlo)
            writetable(getappdata(f,'featureTableGlo2'),[fpath,filesep,fname,'_Glo_Ch2.xlsx'],'WriteVariableNames',0,'WriteRowNames',1);
        end
    end
    
    %% curves
    dffAlignedMat1 = getappdata(f,'dffAlignedMat1');
    ftsLst1 = getappdata(f,'fts1');
    dffAlignedMat2 = getappdata(f,'dffAlignedMat2');
    ftsLst2 = getappdata(f,'fts2');
    fea.outputCurves(dffAlignedMat1, ftsLst1, dffAlignedMat2, ftsLst2, opts, fpath, fname);
    if(opts.detectGlo)
        dffAlignedMatGlo1 = getappdata(f,'dffAlignedMatGlo1');
        ftsGlo1 = getappdata(f,'ftsGlo1');
        dffAlignedMatGlo2 = getappdata(f,'dffAlignedMatGlo2');
        ftsGlo2 = getappdata(f,'ftsGlo2');
        fea.outputCurves(dffAlignedMatGlo1, ftsGlo1, dffAlignedMatGlo2, ftsGlo2, opts, fpath, [fname,'_Glo']);
    end
    
    % for each region
    bd = getappdata(f,'bd');
    ftTb1 = getappdata(f,'featureTable1');
    ftTb2 = getappdata(f,'featureTable2');
    fea.outputRegions(ftsLst1, ftTb1, evtSelectedList1, ftsLst2, ftTb2, evtSelectedList2, bd, opts, fpath, fname);
    if(opts.detectGlo)
        ftsGlo1 = getappdata(f,'ftsGlo1');
        ftsGlo2 = getappdata(f,'ftsGlo2');
        ftTbGlo1 = getappdata(f,'featureTableGlo1');
        ftTbGlo2 = getappdata(f,'featureTableGlo2');
        fea.outputRegions(ftsGlo1, ftTbGlo1, [], ftsGlo2, ftTbGlo2, [], bd, opts, fpath, fname);
    end

    % rising maps
    riseLst1 = getappdata(f,'riseLst1');
    riseLst2 = getappdata(f,'riseLst2');
    fea.outputRisingMap(curSz, dsSclXY, riseLst1, evtFavList1, riseLst2, evtFavList2, opts, fpath,'risingMaps');  % bug fixed 07/17/2025
    if(opts.detectGlo)
        gloRiseLst1 = getappdata(f,'gloRiseLst1');
        gloRiseLst2 = getappdata(f,'gloRiseLst2');
        fea.outputRisingMap(curSz, dsSclXY, gloRiseLst1, 1:numel(gloRiseLst1), gloRiseLst2, 1:numel(gloRiseLst2), opts, fpath,'risingMaps_Glo');
    end

    % landmark map
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
        saveas(f00,[fpath,filesep,fname,'_landmark.png'],'png');
        delete(f00);
    end
end

delete(ff);

end







