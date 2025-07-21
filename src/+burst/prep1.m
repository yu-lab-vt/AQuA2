function [dat1,dat2,opts] = prep1(p1,f1,p2,f2,~,opts,ff)
    % Xuelong 03/21/2023
    % Now 2D video will be converted into 3D video
    
    bdCrop = opts.regMaskGap;
    [filepath1,name1,ext1] = fileparts([p1,filesep,f1]);
    opts.filePath1 = filepath1;
    opts.fileName1 = name1;
    opts.fileType1 = ext1;
    [filepath2,name2,ext2] = fileparts([p2,filesep,f2]);
    opts.filePath2 = filepath2;
    opts.fileName2 = name2;
    opts.fileType2 = ext2;
    
    %% 07/08/2025 added: data waitbar ---------------------
    % Same as the original, use channel 1 if there is only one data set
    % Get file size
    fileInfo1 = dir([p1,filesep,f1]);
    fileSize1 = fileInfo1.bytes;
    if ~isempty(f2)
        fileInfo2 = dir([p2,filesep,f2]);
        fileSize2 = fileInfo2.bytes;
    else
        fileSize2 = 0;
    end
    totalBytes = fileSize1 + fileSize2;
    
    bytesRead = 0;
    lastUpdate = 0;
    
    function updateProgress(bytesAdded)
        bytesRead = bytesRead + bytesAdded;
        progress = bytesRead / totalBytes;
        
        % limit update freq (1% or 0.1GB)
        if progress - lastUpdate > 0.01 || bytesRead - lastUpdate > 1e8
            if exist('ff','var') && isvalid(ff)
                gbRead = bytesRead / 1e9;
                gbTotal = totalBytes / 1e9;
                waitbar(progress, ff, sprintf('Reading data: %.1fGB/%.1fGB', gbRead, gbTotal));
            end
            lastUpdate = progress;
        end
    end
    % -----------------------


    % read data
    fprintf('Reading data\n');
    if strcmp(ext1,'.mat')
        file = load([p1,filesep,f1]);
        headers = fieldnames(file);
        dat1 = single(file.(headers{1}));
        maxImg1 = -1;
        BitDepth1 = -1;
        if(~isempty(f2))
            file = load([p2,filesep,f2]);
            headers = fieldnames(file);
            dat2 = single(file.(headers{1}));
            BitDepth2 = -1;
        else
            dat2 = [];
            BitDepth2 = [];
        end
    else
        % [dat1,BitDepth1] = io.readTiffSeq([p1,filesep,f1]);
        [dat1,BitDepth1] = io.readTiffSeq([p1,filesep,f1], [], @updateProgress);
        if(~isempty(f2))
            % [dat2,BitDepth2] = io.readTiffSeq([p2,filesep,f2]);
            [dat2,BitDepth2] = io.readTiffSeq([p2,filesep,f2], [], @updateProgress);
        else
            dat2 = [];
            BitDepth2 = [];
        end
    end
    
    % Compatible for 3D data
    if numel(size(dat1)) == 3
        dat1 = permute(dat1,[1,2,4,3]);
        if ~isempty(dat2)
            dat2 = permute(dat2,[1,2,4,3]);
        end
    end
    
    dat1 = single(dat1);
    dat2 = single(dat2);
    dat1 = dat1(bdCrop+1:end-bdCrop,bdCrop+1:end-bdCrop,:,:);
    minDat1 = min(dat1(:));%median(min(dat1,[],[1,2]));
    maxDat1 = max(dat1(:)); 
    opts.maxValueDat1 = maxDat1;
    dat1 = dat1 - minDat1;
    dat1(dat1<0) = 0;
    dat1 = dat1/(maxDat1-minDat1);
    opts.minValueDat1 = minDat1;
    if(~isempty(dat2))
        dat2 = dat2(bdCrop+1:end-bdCrop,bdCrop+1:end-bdCrop,:,:);
        minDat2 = min(dat2(:));%median(min(dat2,[],[1,2]));
        dat2 = dat2 - minDat2;
        dat2(dat2<0) = 0;
        maxDat2 = max(dat2(:));
        dat2 = dat2/maxDat2;
        opts.maxValueDat2 = maxDat2;
        opts.minValueDat2 = minDat2;
    end
    
    if exist('ff','var')
        waitbar(0.4,ff);
    end
    
    [H,W,L,T] = size(dat1);
    opts.sz = [H,W,L,T];
    opts.BitDepth = BitDepth1;
end