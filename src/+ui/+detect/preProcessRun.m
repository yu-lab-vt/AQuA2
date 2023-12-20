function preProcessRun(~,~,f)
% ----------- Modified by Xuelong Mi, 02/01/2023 -----------
opts = getappdata(f,'opts');
preSetting = getappdata(f,'preSetting');
disp('Preprocessing');
fh = guidata(f);
ff = waitbar(0,'Image registration ...');

% ----------------- registration, photobleach correction, remove salt and pepper noise ---------------
if(isempty(preSetting) || ~isfield(opts,'alreadyProprecess') || ~opts.alreadyProprecess || ...
        ~strcmp(preSetting.registrateCorrect,fh.registrateCorrect.Value) || ~strcmp(preSetting.bleachCorrect,fh.bleachCorrect.Value) || ...
        opts.medSmo~=str2double(fh.medSmo.Value))
    % 'if' is to judge whether this step is already done. Since this step
    % is time-consuming.
    opts = getappdata(f,'opts');
    datOrg1 = getappdata(f,'datOOrg1');
    datOrg2 = getappdata(f,'datOOrg2');
    if(isempty(datOrg1))
        datOrg1 = getappdata(f,'datOrg1');
        datOrg2 = getappdata(f,'datOrg2');
        setappdata(f,'datOOrg1',datOrg1);
        setappdata(f,'datOOrg2',datOrg2);
    end
    
    opts.registrateCorrect = find(strcmp(fh.registrateCorrect.Value,fh.registrateCorrect.Items));
    opts.bleachCorrect = find(strcmp(fh.bleachCorrect.Value,fh.bleachCorrect.Items));
    preSetting.registrateCorrect = fh.registrateCorrect.Value;
    preSetting.bleachCorrect = fh.bleachCorrect.Value;
    setappdata(f,'preSetting',preSetting);

    % image registration
    if(opts.registrateCorrect == 2)
        tic;
        [datOrg1,datOrg2] = reg.regCrossCorrelation(datOrg1,datOrg2);
        toc;
    elseif(opts.registrateCorrect == 3)
        if(opts.singleChannel)
            [datOrg1,datOrg2] = reg.regCrossCorrelation(datOrg1,datOrg2);
        else
            [datOrg2,datOrg1] = reg.regCrossCorrelation(datOrg2,datOrg1);
        end
    end

    % bleach correction
    waitbar(0.25,ff,'Bleach correction ...');
    if(opts.bleachCorrect==2)
        [datOrg1] = pre.bleach_correct(datOrg1);
        if(~opts.singleChannel)
            [datOrg2] = pre.bleach_correct(datOrg2);
        end
    elseif(opts.bleachCorrect==3)
        [datOrg1] = pre.bleach_correct2(datOrg1,opts);
        if(~opts.singleChannel)
            [datOrg2] = pre.bleach_correct2(datOrg2,opts);
        end
    end

    scl = getappdata(f,'scl');
    scl.hrg = [1,size(datOrg1,1)];
    scl.wrg = [1,size(datOrg1,2)];
    scl.lrg = [1,size(datOrg1,3)];
    setappdata(f,'scl',scl);
    
    % median filter to remove salt and pepper noise 
    opts.medSmo = str2double(fh.medSmo.Value);
    L = size(datOrg1,3);
    if opts.medSmo>0
        medSize = opts.medSmo*2+1;
        for tt=1:size(datOrg1,4)
            for l = 1:L
                datOrg1(:,:,l,tt) = medfilt2(datOrg1(:,:,l,tt),[medSize,medSize]);
            end
        end
        % rescale data to the range 0 and 1
        a = opts.minValueDat1; b = opts.maxValueDat1;
        c = min(datOrg1(:)); d = max(datOrg1(:));
        datOrg1 = (datOrg1 - c)/(d-c);
        % update the values
        opts.minValueDat1 = a + (b-a)*c;
        opts.maxValueDat1 = a + (b-a)*d;
        if(~opts.singleChannel)
            for tt=1:size(datOrg1,4)
                for l = 1:L
                    datOrg2(:,:,l,tt) = medfilt2(datOrg2(:,:,l,tt),[medSize,medSize]);
                end
            end
            a = opts.minValueDat2; b = opts.maxValueDat2;
            c = min(datOrg2(:)); d = max(datOrg2(:));
            datOrg2 = (datOrg2 - c)/(d-c);
            opts.minValueDat2 = a + (b-a)*c;
            opts.maxValueDat2 = a + (b-a)*d;
        end 
    end
    
    opts.alreadyProprecess = true;
    opts.sz = size(datOrg1);
    fh.averPro1 = mean(datOrg1,4);
    fh.averPro2 = mean(datOrg2,4);
    fh.maxPro1 = max(datOrg1,[],4);
    fh.maxPro2 = max(datOrg2,[],4);
    guidata(f,fh);
    setappdata(f,'datOrg1',datOrg1);
    setappdata(f,'datOrg2',datOrg2);
end

waitbar(0.5,ff,'Baseline modeling and noise modeling ...');

% Only consider the pixels in the drawn cells
bd = getappdata(f,'bd');
sz = opts.sz;
evtSpatialMask = true(sz(1:3));
if bd.isKey('cell')
    bd0 = bd('cell');
    if sz(3)==1
        if numel(bd0) > 0
            evtSpatialMask = false(sz(1:3));
            for ii=1:numel(bd0)
                p0 = bd0{ii}{2};
                evtSpatialMask(p0) = true;
            end
        end
    else
        evtSpatialMask = bd0;
    end
end

% F0 bias calculation
opts.movAvgWin = min(opts.movAvgWin,100);   % maximum of table, winSize is 100
opts.cut = min(opts.cut,10000);             % maximum of table, cut is 10000

% load setting
opts.smoXY = str2double(fh.smoXY.Value);

% obtain data
datOrg1 = getappdata(f,'datOrg1');

% smooth + noise estimation + remove background
[dF1,opts] = pre.baselineRemoveAndNoiseEstimation(datOrg1,opts,evtSpatialMask,1,ff);

setappdata(f,'dF1',dF1);
clear dF1 datOrg1;

waitbar(0.75,ff);
if(~opts.singleChannel)
    datOrg2 = getappdata(f,'datOrg2');
    [dF2,opts] = pre.baselineRemoveAndNoiseEstimation(datOrg2,opts,evtSpatialMask,2,ff);
else
    dF2 = [];
end
setappdata(f,'dF2',dF2);
clear dF2 datOrg2;

setappdata(f,'opts',opts);
fh.GaussFilter.Enable = 'on';
waitbar(1,ff);
delete(ff);

disp('Done');
setappdata(f,'opts',opts);

% dF/sigma view
if opts.singleChannel
    fh.movRType.Value = 'dF / sigma';
    fh.sbs.Value = 1;
    ui.mov.movSideBySide([],[],f);
    ui.mov.movViewSel([],[],f);
end

end