% Read Me:
% This script is used to align the FOV of AQuA2 results obtained from
% 2D multi-session datasets.
% It will output AQuA2 results in '.mat' file with same FOV. Events
% detected outside the FOV will be removed. Features will be re-extracted.
% Please put AQuA2 results to be aligned into one folder.
clear;
clc;
startup;

%% setting
pFolder = 'F:\Test_data\multi_session\Session_to_be_aligned\';
pOut = 'F:\Test_data\multi_session\Session_aligned\';
mkdir(pOut);
registrationType = "rigid"; % "translation", "rigid", "similarity", "affine"


%% load
files = dir(fullfile(pFolder,'*AQuA2.mat'));

AQuA2res = cell(numel(files), 1);
for fileID = 1:numel(files)
    AQuA2res{fileID} = load([pFolder, files(fileID).name]).res;
end
ref = rescale(squeeze(mean(single(AQuA2res{1}.datOrg1),4)));
masks = false(size(ref, 1), size(ref, 2), numel(files));

%% regiser
[optimizer,metric] = imregconfig("multimodal");
optimizer.InitialRadius = 0.009;
optimizer.Epsilon = 1.5e-4;
optimizer.GrowthFactor = 1.01;
optimizer.MaximumIterations = 300;

transforms = cell(numel(files), 1);
for fileID = 1:numel(files)
    datPro = rescale(squeeze(mean(single(AQuA2res{fileID}.datOrg1),4)));

    tform = imregtform(datPro,ref,registrationType,optimizer,metric);
    movingRegistered = imwarp(datPro, tform, 'OutputView', imref2d(size(ref)));
    masks(:,:,fileID) = imwarp(true(size(datPro)), tform, 'OutputView', imref2d(size(ref)));
    transforms{fileID} = tform;
end

overlappedRegion = sum(masks, 3) == numel(files);
[x0, x1, y0, y1] = multiAlign.maximalRectangle(overlappedRegion);
H_new = x1 - x0 + 1;
W_new = y1 - y0 + 1;
%% modify
for fileID = 1:numel(files)
    res = AQuA2res{fileID};
    tform = transforms{fileID};
    orgSz = res.opts.sz;
    % dat
    res.datOrg1 = multiAlign.warp(res.datOrg1,tform,ref,x0,x1,y0,y1);
    res.dF1 = multiAlign.warp(res.dF1,tform,ref,x0,x1,y0,y1);

    % opts
    res.opts.sz = size(res.datOrg1);
    res.opts.tempVarOrg = multiAlign.warp(res.opts.tempVarOrg,tform,ref,x0,x1,y0,y1);
    res.opts.tempVarOrg1 = multiAlign.warp(res.opts.tempVarOrg1,tform,ref,x0,x1,y0,y1);
    res.opts.correctPars = multiAlign.warp(res.opts.correctPars,tform,ref,x0,x1,y0,y1);
    res.opts.correctPars1 = multiAlign.warp(res.opts.correctPars1,tform,ref,x0,x1,y0,y1);
    res.opts.stdMap1 = multiAlign.warp(res.opts.stdMap1,tform,ref,x0,x1,y0,y1);
    res.opts.stdMapOrg1 = multiAlign.warp(res.opts.stdMapOrg1,tform,ref,x0,x1,y0,y1);

    % bd
    if res.bd.isKey('cell')
        bd0 = res.bd('cell');
        for ii=1:numel(bd0)
            mask = false(orgSz(1:3));
            p0 = bd0{ii}{2};
            mask(p0) = true;
            mask = multiAlign.warp(mask,tform,ref,x0,x1,y0,y1);
            bd0{ii}{2} = find(mask);
        end
        res.bd('cell') = bd0;
    end
    if res.bd.isKey('landmk')
        bd1 = res.bd('landmk');
        for ii=1:numel(bd1)
            mask = false(orgSz(1:3));
            p0 = bd1{ii}{2};
            mask(p0) = true;
            mask = multiAlign.warp(mask,tform,ref,x0,x1,y0,y1);
            bd1{ii}{2} = find(mask);
        end
        res.bd('landmk') = bd0;
    end

    % evt
    for i = 1:numel(res.evt1)
        pix = res.evt1{i};
        [~,~,~,it] = ind2sub(orgSz, pix);
        t0 = min(it);
        t1 = max(it);
        mask = false([orgSz(1:2), t1 - t0 + 1]);
        mask(pix - orgSz(1)*orgSz(2)*(t0 - 1)) = true;
        mask = multiAlign.warp(mask,tform,ref,x0,x1,y0,y1);
        res.evt1{i} = find(mask) + H_new * W_new * (t0 - 1);
    end

    for i = 1:numel(res.gloEvt1)
        pix = res.gloEvt1{i};
        [~,~,~,it] = ind2sub(orgSz, pix);
        t0 = min(it);
        t1 = max(it);
        mask = false([orgSz(1:2), t1 - t0 + 1]);
        mask(pix - orgSz(1)*orgSz(2)*(t0 - 1)) = true;
        mask = multiAlign.warp(mask,tform,ref,x0,x1,y0,y1);
        res.gloEvt1{i} = find(mask) + H_new * W_new * (t0 - 1);
    end

    remainedEvt = cellfun(@numel, res.evt1) > 0;
    if ~isempty(res.gloEvt1)
        remainedGloEvt = cellfun(@numel, res.gloEvt1) > 0;
    end

    % riseLst
    for i = 1:numel(res.riseLst1)
        rr = res.riseLst1{i};
        mask20 = nan(orgSz(1:2));
        mask50 = nan(orgSz(1:2));
        mask80 = nan(orgSz(1:2));
        mask20(rr.rgh, rr.rgw) = rr.dlyMap20;
        mask50(rr.rgh, rr.rgw) = rr.dlyMap50;
        mask80(rr.rgh, rr.rgw) = rr.dlyMap80;
        mask20 = multiAlign.warp(mask20,tform,ref,x0,x1,y0,y1);
        mask50 = multiAlign.warp(mask50,tform,ref,x0,x1,y0,y1);
        mask80 = multiAlign.warp(mask80,tform,ref,x0,x1,y0,y1);
        [ih, iw] = ind2sub([H_new, W_new], find(~isnan(mask50)));
        rgh = min(ih):max(ih);
        rgw = min(iw):max(iw);
        rr.rgh = rgh;
        rr.rgw = rgw;
        rr.dlyMap20 = mask20(rr.rgh, rr.rgw);
        rr.dlyMap50 = mask50(rr.rgh, rr.rgw);
        rr.dlyMap80 = mask80(rr.rgh, rr.rgw);
        res.riseLst1{i} = rr;
    end

    for i = 1:numel(res.gloRiseLst1)
        rr = res.gloRiseLst1{i};
        mask20 = nan(orgSz(1:2));
        mask50 = nan(orgSz(1:2));
        mask80 = nan(orgSz(1:2));
        mask20(rr.rgh, rr.rgw) = rr.dlyMap20;
        mask50(rr.rgh, rr.rgw) = rr.dlyMap50;
        mask80(rr.rgh, rr.rgw) = rr.dlyMap80;
        mask20 = multiAlign.warp(mask20,tform,ref,x0,x1,y0,y1);
        mask50 = multiAlign.warp(mask50,tform,ref,x0,x1,y0,y1);
        mask80 = multiAlign.warp(mask80,tform,ref,x0,x1,y0,y1);
        [ih, iw] = ind2sub([H_new, W_new], find(~isnan(mask50)));
        rgh = min(ih):max(ih);
        rgw = min(iw):max(iw);
        rr.rgh = rgh;
        rr.rgw = rgw;
        rr.dlyMap20 = mask20(rr.rgh, rr.rgw);
        rr.dlyMap50 = mask50(rr.rgh, rr.rgw);
        rr.dlyMap80 = mask80(rr.rgh, rr.rgw);
        res.gloRiseLst1{i} = rr;
    end

    % remove not used events
    res.evt1 = res.evt1(remainedEvt);
    res.riseLst1 = res.riseLst1(remainedEvt);
    if ~isempty(res.gloEvt1)
        remainedGloEvt = cellfun(@numel, res.gloEvt1) > 0;
        res.gloEvt1 = res.gloEvt1(remainedEvt);
        res.gloRiseLst1 = res.gloRiseLst1(remainedEvt);
    end

    mappingLabels = -ones(numel(remainedEvt), 1);
    cnt = 1;
    for i = 1:numel(remainedEvt)
        if remainedEvt(i)
            mappingLabels(i) = cnt;
            cnt = cnt + 1;
        end
    end

    % others
    res.evtSelectedList1 = mappingLabels(res.evtSelectedList1);
    res.evtSelectedList1 = res.evtSelectedList1(res.evtSelectedList1>0);
    res.evtFavList1 = mappingLabels(res.evtFavList1);
    res.evtFavList1 = res.evtSelectedList1(res.evtFavList1>0);
    res.btSt.filterMsk1 = res.btSt.filterMsk1(remainedEvt);
    res.scl.maxOV = sum(remainedEvt);
    res.scl.H = H_new;
    res.scl.W = W_new;
    res.scl.hrg = [1,H_new];
    res.scl.wrg = [1,W_new];

    % ov
    ov = containers.Map('UniformValues',0);
    ov('None') = [];
    ov0 = res.ov('Events_Red');
    ovName = 'Events';
    datR1 = fea.reconstructDatR(ov0, orgSz);
    datR1 = multiAlign.warp(datR1,tform,ref,x0,x1,y0,y1);
    ov1 = ui.over.getOv([],res.evt1,res.opts.sz,datR1,1);
    ov1.name = ovName;
    ov1.colorCodeType = {'Random'};
    ov([ovName,'_Red']) = ov1;
    ov2 = ui.over.getOv([],[],res.opts.sz,[],2);
    ov2.name = ovName;
    ov2.colorCodeType = {'Random'};
    ov([ovName,'_Green']) = ov2;

    if ~isempty(res.gloEvt1)
        ov0 = ov('Global Events_Red');
        ovName = 'Global Events';
        datRGlo1 = fea.reconstructDatR(ov0,orgSz);
        ov1 = ui.over.getOv([],res.gloEvt1,opts.sz,gloDatR1,1);
        ov1.name = ovName;
        ov1.colorCodeType = {'Random'};
        ov([ovName,'_Red']) = ov1;
        ov2 = ui.over.getOv([],[],res.opts.sz,[],2);
        ov2.name = ovName;
        ov2.colorCodeType = {'Random'};
        ov([ovName,'_Green']) = ov2;
    end
    res.ov = ov;

    % reCalculate Features
    disp('Feature extration...');
    res.opts.maxValueDat = res.opts.maxValueDat1;
    res.opts.minValueDat = res.opts.minValueDat1;
    [fts1, dffMat1, dMat1, dffAlignedMat1] = fea.getFeaturesTop(res.datOrg1, res.evt1, res.opts, []);
    fts1.channel = 1;

    if ~isempty(res.gloEvt1)
        [ftsGlo1, ~, ~,~] = fea.getFeaturesTop(res.datOrg1, res.gloEvt1, res.opts, []);
        ftsGlo1.channel = 1;
    else
        ftsGlo1 = []; 
    end
    res.fts1 = fts1;
    res.dffMat1 = dffMat1;
    res.dMat1 = dMat1;
    res.dffAlignedMat1 = dffAlignedMat1;
    res.ftsGlo1 = ftsGlo1;

    name = [files(fileID).name(1:end-4)];
    disp('Saving result...');
    save([pOut,'Align_',name,'.mat'], 'res','-v7.3');   
end