function writeTiffSeq( fName, dat, bitDepth, rescale )
% WRITEIFFSEQ Write image sequence using Tiff object for performance
% Optimized for large files
% Updated 2025/11/02

% --- Input Handling ---
if ~exist('rescale','var')
    rescale = 0;
end

if ~exist('bitDepth','var')
    % 3D assumes 16-bit, others 8-bit
    if ndims(dat) == 3
        bitDepth = 16;
    else
        bitDepth = 8;
    end
end

% --- Data Pre-processing ---
if rescale
    dat = double(dat);
    dat = dat / max(dat(:));
end

if bitDepth > 0
    if bitDepth == 8
        dat = uint8(round(dat * 255));
    elseif bitDepth == 16
        dat = uint16(round(dat * 65535));
    end
end

% --- Tiff Object Initialization ---
% Use 'w8' for BigTIFF support (>4GB files)
t = Tiff(fName, 'w8');

% Ensure file is closed if error occurs
cleanupObj = onCleanup(@() close(t));

% Get dimensions
dims = size(dat);
h = dims(1);
w = dims(2);

% --- Tag Configuration Setup ---
tagstruct.ImageLength = h;
tagstruct.ImageWidth = w;
tagstruct.Photometric = Tiff.Photometric.MinIsBlack; % Default to grayscale
tagstruct.BitsPerSample = bitDepth;
tagstruct.SamplesPerPixel = 1;
tagstruct.RowsPerStrip = h; % Write entire image as one strip for speed
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software = 'MATLAB';
tagstruct.Compression = Tiff.Compression.None; % Fastest writing

% --- Writing Loop ---

% Case 1: 2D Image (Single Frame)
if ndims(dat) == 2
    t.setTag(tagstruct);
    t.write(dat);
end

% Case 2: 3D Stack (Grayscale Sequence: H x W x D)
if ndims(dat) == 3
    numFrames = dims(3);
    for ii = 1:numFrames
        if ii > 1
            t.writeDirectory(); % Start new frame
        end
        t.setTag(tagstruct);
        t.write(dat(:,:,ii));
    end
end

% Case 3: 4D Stack (Color Sequence: H x W x C x D)
if ndims(dat) == 4
    numFrames = dims(4);
    
    % Update tags for RGB
    tagstruct.Photometric = Tiff.Photometric.RGB;
    tagstruct.SamplesPerPixel = 3; 
    
    for ii = 1:numFrames
        if ii > 1
            t.writeDirectory(); % Start new frame
        end
        t.setTag(tagstruct);
        % Permute might be needed if data is not interleaved correctly, 
        % but Tiff.write expects HxWx3 for chunky RGB.
        t.write(dat(:,:,:,ii));
    end
end

clear cleanupObj; 

end