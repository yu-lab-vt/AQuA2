function readMsk(~,~,f,srcType,mskType,initThr)
    
    % read mask data
    opts = getappdata(f,'opts');
    btSt = getappdata(f,'btSt');
    bdCrop = opts.regMaskGap;
    if isfield(btSt,'mskFolder') && ~isempty(btSt.mskFolder)
        p0 = btSt.mskFolder;
    else
        p0 = opts.filePath1;
    end
    if ~exist('initThr','var')
        initThr = [];
    end
    ff = waitbar(0,'Loading ...');
   
    bdCrop = opts.regMaskGap;
    
    if strcmp(srcType,'file')
        [FileName,PathName] = uigetfile({'*.tif','*.tiff'},'Choose movie',p0);
        if ~isempty(FileName) && ~isnumeric(FileName)
            fIn = [PathName,FileName];
        else
            delete(ff);
            msgbox('Cannot find file','Error');
            return
        end
        dat = io.readTiffSeq(fIn);
        dat = dat/max(dat(:));
        ffName = FileName;
        dat = dat(bdCrop+1:end-bdCrop,bdCrop+1:end-bdCrop,:,:);
        datSz = size(dat);
        if numel(datSz) ~= numel(opts.sz) || datSz(1)~=opts.sz(1) || datSz(2)~=opts.sz(2) || datSz(3)~=opts.sz(3)
            msgbox('Mask size not matched','Error');
            delete(ff);
            return;
        end
    elseif strcmp(srcType,'folder')
        PathName = uigetdir(p0,'Stack folder');
        if ~isempty(PathName) && ~isnumeric(PathName)
            dd = dir([PathName,filesep,'*.tif']);
            if isempty(dd)
                delete(ff);
                msgbox('No file','Error');
                return
            end
            ff = waitbar(0,'Reading...');
            dat = double(imread([PathName,filesep,dd(1).name]));
            for ii=2:numel(dd)
                waitbar(ii/numel(dd),ff);
                dat = dat + double(imread([PathName,filesep,dd(ii).name]));
            end
            delete(ff);
            dat = dat/numel(dd);
            xx = strsplit(PathName,filesep);
            ffName = [xx{end},'-folder'];
        else
            msgbox('Cannot find file','Error');
            delete(ff);
            return
        end
        dat = dat(bdCrop+1:end-bdCrop,bdCrop+1:end-bdCrop,:,:);
        datSz = size(dat);
        if numel(datSz) ~= numel(opts.sz) || datSz(1)~=opts.sz(1) || datSz(2)~=opts.sz(2) || datSz(3)~=opts.sz(3)
            msgbox('Mask size not matched','Error');
            delete(ff);
            return;
        end
    elseif strcmp(srcType,'self_CH1')
        PathName = p0;
        fh = guidata(f);
        dat = fh.averPro1;
        ffName = 'Project data';
    elseif strcmp(srcType,'self_CH2')&&(~opts.singleChannel)
        PathName = p0;
        fh = guidata(f);
        dat = fh.averPro2;
        ffName = 'Project data';
    else
        delete(ff);
        return
    end
    
    L = opts.sz(3);
    
    btSt.mskFolder = PathName;
    setappdata(f,'btSt',btSt);
    % mean projection
    
%     dat = squeeze(dat);
    if numel(size(dat))==4
        datAvg = mean(dat,4);
    else
        datAvg = dat;
    end
    datAvg = datAvg/nanmax(datAvg(:));
    
    % adjust contrast
    % thresholding and sizes of components
    if isempty(initThr)
        if L==1
            datAvg = imadjust(datAvg,stretchlim(datAvg,0.001));
            datLevel = graythresh(datAvg);
        else
            datLevel = mean(datAvg(:));
        end
    else
        datLevel = initThr;
    end
    [H,W,L] = size(datAvg);
    
    % mask object
    rr = [];
    rr.name = ffName;
    rr.datAvg = datAvg;
    rr.type = mskType;
    rr.thr = datLevel;
    rr.minSz = 1;
    rr.maxSz = H*W*L;
    rr.mask = zeros(size(datAvg));
    rr.morphoChange = 0;
    
    bd = getappdata(f,'bd');
    if ~isempty(bd) && bd.isKey('maskLst')
        bdMsk = bd('maskLst');
    else
        bdMsk = [];
    end
    bdMsk{end+1} = rr;
    bd('maskLst') = bdMsk;
    setappdata(f,'bd',bd);
    
    waitbar(1,ff);
    % update mask list, image view and slider values
    ui.msk.mskLstViewer([],[],f,'refresh');
    delete(ff);
    
end






