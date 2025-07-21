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
% updated 07/18/2025

% --- 1. Argument validation ---
if ~exist('rescaleImg', 'var') || isempty(rescaleImg)
    rescaleImg = false;
end
if ~exist('progressCallback', 'var')
    progressCallback = [];
end

% --- 2. Initial file inspection with imfinfo ---
try
    info = imfinfo(fName);
catch ME
    error('Fatal error: imfinfo could not read file "%s". The file may be corrupt or inaccessible. Error: %s', fName, ME.message);
end

% Extract key parameters for decision making and for the fread fallback
H = info(1).Height;
W = info(1).Width;
BitDepth = info(1).BitDepth;
isStriped = info(1).RowsPerStrip < H;
isMultiDirectory = numel(info) > 1;

% --- 3. Decision Logic: Choose the reading strategy ---
if isStriped || isMultiDirectory
    % --- STRATEGY A: Use robust Tiff class for striped or standard multi-frame files ---
    fprintf('File appears striped or as a standard multi-directory TIFF.\n');
    fprintf('Using robust Tiff class method...\n');
    
    try
        t = Tiff(fName, 'r');
        
        % Determine total frames by iterating through directories
        nFrames = 1;
        while ~t.lastDirectory()
            t.nextDirectory();
            nFrames = nFrames + 1;
        end
        t.setDirectory(1); % Reset to the beginning
        
        isFloat = false;
        if BitDepth == 32 && t.getTag('SampleFormat') == Tiff.SampleFormat.IEEEFP
            isFloat = true;
        end
        
        fprintf('  - Dimensions: %d x %d, Frames: %d, Bit Depth: %d\n', W, H, nFrames, BitDepth);

        img = zeros(H, W, nFrames, 'single');
        maxVal = 2^BitDepth - 1;
        
        fprintf('Reading image stack... 0%%');
        last_percent_shown = 0;
        
        for k = 1:nFrames
            t.setDirectory(k);
            frame = t.read();
            if size(frame, 3) > 1, frame = mean(frame, 3); end
            
            if rescaleImg && ~isFloat
                img(:, :, k) = single(frame) / maxVal;
            else
                img(:, :, k) = single(frame);
            end
            
            if isa(progressCallback, 'function_handle')
                progressCallback(H * W * (BitDepth / 8));
            end

            percent_done = floor(k / nFrames * 100);
            if percent_done > last_percent_shown && mod(percent_done, 10) == 0
                fprintf('...%d%%', percent_done);
                last_percent_shown = percent_done;
            end
        end
        fprintf('...100%% Done.\n');
        t.close();
        
    catch ME
        if exist('t', 'var'), t.close(); end
        rethrow(ME);
    end
    
else
    % --- STRATEGY B: Fallback to fread for large, single-directory contiguous files ---
    fprintf('File appears as a large, single-directory contiguous TIFF.\n');
    fprintf('Using high-performance fread fallback method...\n');
    
    try
        % Reliably get file size for frame calculation
        f_tmp = fopen(fName, 'r');
        fseek(f_tmp, 0, 'eof');
        fileSize = ftell(f_tmp);
        fclose(f_tmp);
        
        bytesPerFrame = H * W * (BitDepth / 8);
        nFrames = floor((fileSize - info(1).StripOffsets(1)) / bytesPerFrame);
        
        isFloat = false;
        switch BitDepth
            case 8, precision = 'uint8=>uint8';
            case 16, precision = 'uint16=>uint16';
            case 32
                if isfield(info(1), 'SampleFormat') && strcmp(info(1).SampleFormat, 'IEEE floating point')
                    precision = 'single=>single'; isFloat = true;
                else
                    precision = 'uint32=>uint32';
                end
            otherwise, error('Unsupported bit depth: %d.', BitDepth);
        end
        
        if strcmp(info(1).ByteOrder, 'little-endian'), machineFormat = 'l'; else machineFormat = 'b'; end
        
        fprintf('  - Dimensions: %d x %d, Est. Frames: %d, Bit Depth: %d\n', W, H, nFrames, BitDepth);
        
        img = zeros(H, W, nFrames, 'single');
        maxVal = 2^BitDepth - 1;
        
        fID = fopen(fName, 'r', machineFormat);
        start_points = info(1).StripOffsets(1) + (0:1:(nFrames-1)) * bytesPerFrame;
        
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

            percent_done = floor(k / nFrames * 100);
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