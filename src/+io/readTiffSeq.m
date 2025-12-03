function [img, BitDepth] = readTiffSeq(fName, rescaleImg, progressCallback)
% readTiffSeq: Reads large TIFF image sequences using a hybrid strategy.
%
% This function intelligently chooses the best method to read a TIFF file.
% It uses MATLAB's robust 'Tiff' class for standard or striped files, and
% falls back to a high-performance, low-level 'fread' method for very large
% (>4GB) contiguous files that may confuse standard parsers.
%
% SYNTAX:
%   [img, BitDepth] = readTiffSeq(fName, rescaleImg, progressCallback)
%
% INPUTS:
%   fName            - (string) Full path to the TIFF file.
%   rescaleImg       - (logical, optional) If true, integer pixel values are
%                      normalized to the [0, 1] range. Defaults to false.
%   progressCallback - (function_handle, optional) A callback function for
%                      progress updates.
%
% OUTPUTS:
%   img              - (H x W x nFrames, single) The loaded image stack.
%   BitDepth         - (double) The bit depth of the image (e.g., 8, 16, 32).
%
% updated 2025/12/03 (Optimized init & sequential read)

% --- 1. Argument validation ---
if ~exist('rescaleImg', 'var') || isempty(rescaleImg)
    rescaleImg = false;
end
if ~exist('progressCallback', 'var')
    progressCallback = [];
end

% --- 2. Initial file inspection (Optimized) ---
% Replaced imfinfo with low-level check + Tiff class for speed
d = dir(fName);
if isempty(d), error('File not found: %s', fName); end
fileSize = d.bytes;

try
    t = Tiff(fName, 'r');
    
    % Read key parameters from first frame only
    W = t.getTag('ImageWidth');
    H = t.getTag('ImageLength');
    BitDepth = t.getTag('BitsPerSample');
    
    try rowsPerStrip = t.getTag('RowsPerStrip'); catch, rowsPerStrip = H; end
    isStriped = rowsPerStrip < H;
    
    % Check for compression and sample format
    try comp = t.getTag('Compression'); catch, comp = 1; end
    try sampleFmt = t.getTag('SampleFormat'); catch, sampleFmt = Tiff.SampleFormat.UInt; end
    
    isFloat = (BitDepth == 32 && sampleFmt == Tiff.SampleFormat.IEEEFP);
    
    % Get StripOffsets for Strategy B fallback
    try firstOffset = t.getTag('StripOffsets'); catch, firstOffset = 0; end
    
catch ME
    if exist('t', 'var'), close(t); end
    error('Fatal error: Tiff class could not read file "%s". Error: %s', fName, ME.message);
end

% --- 3. Decision Logic: Choose the reading strategy ---
% Only use Strategy B if strictly uncompressed, not striped, and very large
useFread = (comp == 1) && (~isStriped) && (fileSize > 2^32);

if ~useFread
    % --- STRATEGY A: Use robust Tiff class (Optimized Sequential) ---
    fprintf('File appears striped or as a standard multi-directory TIFF.\n');
    fprintf('Using robust Tiff class method (Optimized)...\n');
    
    try
        % Estimate frames from file size to avoid full traversal (O(1))
        bytesPerFrame = W * H * (BitDepth / 8);
        estFrames = floor(fileSize / bytesPerFrame);
        if estFrames < 1, estFrames = 1; end
        
        fprintf('  - Dimensions: %d x %d, Est. Frames: %d, Bit Depth: %d\n', W, H, estFrames, BitDepth);

        img = zeros(H, W, estFrames, 'single');
        maxVal = 2^BitDepth - 1;
        
        fprintf('Reading image stack... 0%%');
        last_percent_shown = 0;
        
        % Ensure we are at start
        if t.currentDirectory() ~= 1, t.setDirectory(1); end
        
        k = 0;
        while true
            k = k + 1;
            
            % Dynamic resize if estimation was too low
            if k > size(img, 3), img(:, :, k+100) = 0; end
            
            frame = t.read();
            if size(frame, 3) > 1, frame = mean(frame, 3); end
            
            if rescaleImg && ~isFloat
                img(:, :, k) = single(frame) / maxVal;
            else
                img(:, :, k) = single(frame);
            end
            
            if isa(progressCallback, 'function_handle')
                progressCallback(bytesPerFrame);
            end

            percent_done = floor(k / estFrames * 100);
            if percent_done >= last_percent_shown + 10
                fprintf('...%d%%', percent_done);
                last_percent_shown = percent_done;
            end
            
            % Efficiently move to next directory (O(1))
            if t.lastDirectory()
                break;
            else
                t.nextDirectory();
            end
        end
        
        % Trim final array to actual size
        if k < size(img, 3), img = img(:, :, 1:k); end
        
        fprintf('...100%% Done.\n');
        t.close();
        
    catch ME
        if exist('t', 'var'), t.close(); end
        rethrow(ME);
    end
    
else
    % --- STRATEGY B: Fallback to fread for large, single-directory contiguous files ---
    % Release Tiff object lock before using fread
    t.close();
    
    fprintf('File appears as a large, single-directory contiguous TIFF.\n');
    fprintf('Using high-performance fread fallback method...\n');
    
    try
        % Reliably determine Byte Order from file header (since imfinfo is gone)
        fid_temp = fopen(fName, 'r');
        header = fread(fid_temp, 2, 'uint8=>char')';
        fclose(fid_temp);
        
        if strcmp(header, 'II')
            machineFormat = 'l'; % Little-endian
        else
            machineFormat = 'b'; % Big-endian
        end

        bytesPerFrame = W * H * (BitDepth / 8);
        nFrames = floor((fileSize - firstOffset(1)) / bytesPerFrame);
        
        isFloat = false;
        switch BitDepth
            case 8, precision = 'uint8=>uint8';
            case 16, precision = 'uint16=>uint16';
            case 32
                if exist('sampleFmt','var') && sampleFmt == Tiff.SampleFormat.IEEEFP
                    precision = 'single=>single'; isFloat = true;
                else
                    precision = 'uint32=>uint32';
                end
            otherwise, error('Unsupported bit depth: %d.', BitDepth);
        end
        
        fprintf('  - Dimensions: %d x %d, Est. Frames: %d, Bit Depth: %d\n', W, H, nFrames, BitDepth);
        
        img = zeros(H, W, nFrames, 'single');
        maxVal = 2^BitDepth - 1;
        
        fID = fopen(fName, 'r', machineFormat);
        start_points = firstOffset(1) + (0:1:(nFrames-1)) * bytesPerFrame;
        
        fprintf('Reading image stack... 0%%');
        last_percent_shown = 0;
        
        for k = 1:nFrames
            fseek(fID, start_points(k), 'bof');
            frame_raw = fread(fID, [W H], precision);
            
            if numel(frame_raw) ~= (W*H)
                nFrames = k - 1; img = img(:,:,1:nFrames);
                warning('File ended prematurely. Read %d frames.', nFrames);
                break;
            end
            
            frame = frame_raw';
            
            if rescaleImg && ~isFloat
                img(:, :, k) = single(frame) / maxVal;
            else
                img(:, :, k) = single(frame);
            end
            
            if isa(progressCallback, 'function_handle'), progressCallback(bytesPerFrame); end

            percent_done = floor(k * 100.0 / nFrames);
            if percent_done > last_percent_shown && mod(percent_done, 10) == 0
                fprintf('...%d%%', percent_done);
                last_percent_shown = percent_done;
            end
        end
        fprintf('...100%% Done.\n');
        fclose(fID);
        
    catch ME
        if exist('fID', 'var') && fID ~= -1, fclose(fID); end
        rethrow(ME);
    end
end

end