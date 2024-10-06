%Mark Bright - 2024
function [img,BitDepth] = readSingleFrameMaskTif(fName)
    info = imfinfo(fName);
    BitDepth = info(1).BitDepth;
    maxVal = 2^(BitDepth)-1;
    H = info(1).Height;
    W = info(1).Width;
    oneFrame = imread(fName, 1);

    activeAreaQuestion = questdlg('In your mask, is white or black the active area? We may need to invert it so that white is the active area and black is the mask...','Active area is?','White','Black','Option 1');
    switch activeAreaQuestion
        case 'White'
            oneFrame(oneFrame ~= min(oneFrame(:))) = maxVal;
            oneFrame(oneFrame == min(oneFrame(:))) = 0;
        case 'Black'
            oldmin = min(oneFrame(:));
            oneFrame(oneFrame ~= oldmin) = 0;
            oneFrame(oneFrame == oldmin) = maxVal;
        otherwise
            oneFrame(oneFrame ~= min(oneFrame(:))) = maxVal;
            oneFrame(oneFrame == min(oneFrame(:))) = 0;
    end

    prompt = {'It is recommended to perform gaussian smoothing on your mask, otherwise, you may overload the mechanism for defining active regions...'};
    dlgtitle = 'Input gaussian smoothing parameter:';
    dims = [1 35];
    definput = {'0.6'};

    gausssmoothvalue = inputdlg(prompt, dlgtitle, dims, definput);

    if ~isempty(gausssmoothvalue)
        gsv = str2double(gausssmoothvalue{1});
        if isnan(gsv)
            gausssmoothvalue = 0.6;
            disp('The input is not a valid number. Default value used...');
        else
            gausssmoothvalue = gsv;
        end
    else
        gausssmoothvalue = 0.6;
    end

    prompt = {'It is recommended to set a minimum pixel group size for your mask. Many small groups of pixels may not be useful and contribute to overloading the mechanism for defining active regions...'};
    dlgtitle = 'Minimum size for grouped mask pixels:';
    dims = [1 35];
    definput = {'150'};

    mingroupsize = inputdlg(prompt, dlgtitle, dims, definput);

    if ~isempty(mingroupsize)
        mgs = str2double(mingroupsize{1});
        if isnan(mgs)
            mingroupsize = 150;
            disp('The input is not a valid number. Default value used...');
        else
            mingroupsize = mgs;
        end
    else
        mingroupsize = 150;
    end

    prompt = {'You may add a border to your mask, which simply masks pixels that are within the specified distance from the border... This may mitigate erratic behaviour during defining of active region polygons...'};
    dlgtitle = 'Thickness of mask border:';
    dims = [1 35];
    definput = {'0'};

    borderthickness = inputdlg(prompt, dlgtitle, dims, definput);

    if ~isempty(borderthickness)
        mgs = str2double(borderthickness{1});
        if isnan(mgs)
            borderthickness = 0;
            disp('The input is not a valid number. Default value used...');
        else
            borderthickness = mgs;
        end
    else
        borderthickness = 0;
    end

    img = zeros(H, W, 1, 'single');
    oneFrame = imgaussfilt(oneFrame, gausssmoothvalue);
    oneFrame = ~oneFrame;
    oneFrame = bwareaopen(oneFrame, mingroupsize);
    oneFrame = ~oneFrame;
    oneFrame(1:borderthickness, :) = 0;
    oneFrame(end-borderthickness+1:end, :) = 0;
    oneFrame(:, 1:borderthickness) = 0;
    oneFrame(:, end-borderthickness+1:end) = 0;
    img(:,:,1) = oneFrame;
end

