function prep(~,~,f,op,res)
% read data or load experiment
% op
% 0: new project
% 1: load project or saved results
% 2: load from workspace
% FIXME: udpate GUI settings (btSt), instead of re-build it

fprintf('Loading ...\n');
ff = waitbar(0,'Loading ...');

% cfgFile = 'uicfg.mat';
% if ~exist(cfgFile,'file')
%     cfg0 = [];
% else
%     cfg0 = load(cfgFile);
% end

if ~exist('op','var') || isempty(op)
    op = 0;
end

fh = guidata(f);

% new project
if op==0
    preset = find(strcmp(fh.preset.Items,fh.preset.Value));
    opts = util.parseParam(preset);
    opts.preset = preset;
    
    % read user input
    try
        % if ~strcmp(fh.tmpRes.Value,'As preset')
            opts.frameRate = str2double(fh.tmpRes.Value);
        % end
        % if ~strcmp(fh.spaRes.Value,'As preset')
            opts.spatialRes = str2double(fh.spaRes.Value);
        % end
        % if ~strcmp(fh.bdSpa.Value,'As preset')
            opts.regMaskGap = str2double(fh.bdSpa.Value);
        % end
    catch
        % msgbox('Invalid input');
        % return
    end
    
    try
        pf1 = fh.fIn1.Value;
        pf2 = fh.fIn2.Value;
        [filepath1,name1,ext1] = fileparts(pf1);
        [filepath2,name2,ext2] = fileparts(pf2);
        f.Name = ['AQUA2: ',name1,' ',name2];
        [datOrg1,datOrg2,opts] = burst.prep1(filepath1,[name1,ext1],filepath2,[name2,ext2],[],opts,ff);
    catch
        msgbox('Fail to load file');
        return
    end

    maxPro1 = max(datOrg1,[],4);
    maxPro2 = max(datOrg2,[],4);
    fh.maxPro1 = maxPro1;
    fh.maxPro2 = maxPro2;
    fh.averPro1 = mean(datOrg1,4);
    fh.averPro2 = mean(datOrg2,4);
    fh.showcurves = [];
    opts.maxdF1 = 1;
    opts.maxdF2 = 1;
    if opts.sz(3)>1
        ui.com.uiUpdateFor3D(f,fh,datOrg1(:,:,:,1));
        fh = guidata(f);
    end

    guidata(f,fh);
    
    if(isempty(datOrg2))
       opts.singleChannel = true; 
    else
        opts.singleChannel = false; 
    end
    
    opts.alreadyBleachCorrect = 0;
    
    % UI data structure
    [ov,bd,scl,btSt] = ui.proj.prepInitUIStruct(datOrg1,opts); %#ok<ASGLU>

    opts.enableTab = 1;
    fh.deOutTab.Children(1).ForegroundColor = [0,0,0];

    % data and settings
    vBasic = {'opts','scl','btSt','ov','bd','datOrg1','datOrg2'};
    for ii=1:numel(vBasic)
        v0 = vBasic{ii};
        if exist(v0,'var')
            setappdata(f,v0,eval(v0));
        else
            setappdata(f,v0,[]);
        end
    end
    stg = [];
    stg.detect = 0;
end

% read existing project or mat file
if op>0
    if op==1
        fexp = getappdata(f,'fexp');
        tmp = load(fexp);
        res = tmp.res;
    end
    
    opts = res.opts;
    % rescale int8 to [0,1] double
    % dat is for detection, datOrg for viewing
    %res.dat = double(res.dat)/(2^res.opts.bitNum-1);
    if isfield(res,'datOrg1')
        if ~isfield(opts,'minValueDat1')
            opts.minValueDat1 = 0;
            opts.minValueDat2 = 0;
            opts.maxValueDat1 = 1;
            opts.maxValueDat2 = 1;
        end
        res.datOrg1 = (single(res.datOrg1)-opts.minValueDat1)/(opts.maxValueDat1-opts.minValueDat1);
        if ~opts.singleChannel
            res.datOrg2 = (single(res.datOrg2)-opts.minValueDat2)/(opts.maxValueDat2-opts.minValueDat2);
        else
            res.datOrg2 = [];
        end
    else
        res.datOrg1 = double(res.dat1);
        res.datOrg2 = double(res.dat2);
    end
    
    dat1 = res.datOrg1;
    dat2 = res.datOrg2;
    
    if numel(size(dat1)) == 3 % convert 2D video to 3D video
        dat1 = permute(dat1,[1,2,4,3]);
        if ~isempty(dat1)
            dat2 = permute(dat2,[1,2,4,3]);
        end
    end
    res.datOrg1 = dat1;
    res.datOrg2 = dat2;
    opts.sz = size(dat1);
    fh.maxPro1 = max(dat1,[],4);
    fh.maxPro2 = max(dat2,[],4);
    fh.averPro1 = mean(dat1,4);
    fh.averPro2 = mean(dat2,4);
    if opts.sz(3)>1
        ui.com.uiUpdateFor3D(f,fh,res.datOrg1(:,:,:,1));
        fh = guidata(f);
    end
    guidata(f,fh);
    
    if res.opts.smoXY>0
        for tt=1:size(dat1,4)
            dat1(:,:,:,tt) = imgaussfilt(dat1(:,:,:,tt),res.opts.smoXY);
            if ~isempty(dat2)
                dat2(:,:,:,tt) = imgaussfilt(dat2(:,:,:,tt),res.opts.smoXY);
            end
        end
    end
    
    res.dat1 = dat1;
    res.dat2 = dat2;
    
    waitbar(0.5,ff);
    
    if ~isfield(res,'scl')
        if isfield(res,'bd')
            [~,~,res.scl,res.btSt] = ui.proj.prepInitUIStruct(res.datOrg1,res.opts);
        else
        [~,res.bd,res.scl,res.btSt] = ui.proj.prepInitUIStruct(res.datOrg1,res.opts);
        end
        res.stg = [];
        res.stg.detect = 1;
        res.stg.post = 1;
    else
        [~,~,res.scl,res.btSt] = ui.proj.prepInitUIStruct(res.datOrg1,res.opts,res.btSt);
    end

    fh.movLType.Value = res.btSt.leftView;
    fh.movRType.Value = res.btSt.rightView;

    % reset some settings
    if ~isfield(res,'dbg') || res.dbg==0
        res.btSt.overlayDatSel = 'Events';
    end
    res.btSt.clickSt = [];
    scl = res.scl;
    stg = res.stg;
    ov = res.ov;
    if(~opts.singleChannel)
        fh.nEvt.Text = [num2str(numel(res.evt1)),' | ',num2str(numel(res.evt2))];
    else
        fh.nEvt.Text = [num2str(numel(res.evt1))];
    end
    
    f.Name = ['AQUA: ',opts.fileName1,' ',opts.fileName2];

    fh.deOutTab.Children(end).ForegroundColor = [0,0,0];
    fh.deOutRun.Text = 'Extract';
    fh.deOutNext.Text = 'CFU detect';
   
    fns = fieldnames(res);
    for ii=1:numel(fns)
        f00 = fns{ii};
        setappdata(f,f00,res.(f00));
    end
    if opts.sz(3)>1
        fh.sldMov.Value = 1;
        ui.over.adjTrans3D([],[],f,'All');
    end
    opts.isLoadData = true;
    setappdata(f,'opts',opts);
    
    f.Visible = 'off';
    f.Visible = 'on';
    
end

waitbar(1,ff);
btSt = getappdata(f,'btSt');
if opts.singleChannel
    fh.TextBri1.Text = '  Intensity Brightness';
    fh.TextBri2.Visible = 'off';
    delete(fh.sldBri2);
    fh.sldBri1.Layout.Column = [1,2];
    btSt.ChannelL = 1;
    btSt.ChannelR = 1;
    for i = 1:numel(fh.pChannel.Children)
        fh.pChannel.Children(i).Enable = 'off';
    end
    fh.channelOptionR.Value = 'Channel 1';
else
    btSt.ChannelL = 1;
    btSt.ChannelR = 2;
    fh.movRType.Value = 'Raw + overlay';
    fh.sbs.Value = 1;
    fh.sbs.BackgroundColor = [0.8 0.8 0.8];
    fh.sbs.Enable = 'off';
    fh.bMov1Top.Visible = 'off';
    fh.bMov2Top.Visible = 'on';
    fh.pBrightness.Visible = 'off';
    fh.pBrightnessSideBySide.Visible = 'on';
end
setappdata(f,'btSt',btSt);

if opts.sz(3)==1
    fh.ims.im1.CData = flipud(cat(3,fh.averPro1,fh.averPro1,fh.averPro1));
    fh.ims.im2a.CData = flipud(cat(3,fh.averPro1,fh.averPro1,fh.averPro1));
    if opts.singleChannel
        fh.ims.im2b.CData = flipud(cat(3,fh.averPro1,fh.averPro1,fh.averPro1));
    else
        fh.ims.im2b.CData = flipud(cat(3,fh.averPro2,fh.averPro2,fh.averPro2));
    end
end

% UI
ui.proj.prepInitUI(f,fh,opts,scl,ov,stg,op);

fprintf('Done ...\n');
delete(ff);

end











