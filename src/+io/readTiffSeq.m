function [img, BitDepth] = readTiffSeq(fName, rescaleImg, progressCallback)
% readTiffSeq: Reads large TIFF image sequences using a hybrid strategy.
%
% Updated 2025/12/08: Fixed progress bar issue for compressed TIFFs.
% Now reports progress based on "File Share" rather than "Raw Memory Size".

% --- 1. Argument validation ---
if ~exist('rescaleImg', 'var') || isempty(rescaleImg)
    rescaleImg = false;
end
if ~exist('progressCallback', 'var')
    progressCallback = [];
end

% --- 2. Initial file inspection ---
d = dir(fName);
if isempty(d), error('File not found: %s', fName); end
fileSize = d.bytes;

try
    t = Tiff(fName, 'r');
    
    % Read key parameters
    W = t.getTag('ImageWidth');
    H = t.getTag('ImageLength');
    BitDepth = t.getTag('BitsPerSample');
    
    try rowsPerStrip = t.getTag('RowsPerStrip'); catch, rowsPerStrip = H; end
    isStriped = rowsPerStrip < H;
    
    try comp = t.getTag('Compression'); catch, comp = 1; end
    try sampleFmt = t.getTag('SampleFormat'); catch, sampleFmt = Tiff.SampleFormat.UInt; end
    
    isFloat = (BitDepth == 32 && sampleFmt == Tiff.SampleFormat.IEEEFP);
    
    try firstOffset = t.getTag('StripOffsets'); catch, firstOffset = 0; end
    
catch ME
    if exist('t', 'var'), close(t); end
    error('Fatal error: Tiff class could not read file "%s". Error: %s', fName, ME.message);
end

% --- 3. Decision Logic ---
% Only use Strategy B (fread) if strictly uncompressed, not striped, and very large.
useFread = (comp == 1) && (~isStriped) && (fileSize > 2^32);

if ~useFread
    % --- STRATEGY A: Robust Tiff Class (Optimized for Compressed/Striped) ---
    fprintf('File uses Tiff class (Compressed/Striped/Standard).\n');
    
    try
        % Determine Frames and Progress Increment
        isCompressed = (comp ~= 1);
        bytesPerFrameRaw = W * H * (BitDepth / 8); % Size in Memory
        
        if isCompressed
            % If compressed, file size does not correlate linearly to frame count.
            % We MUST scan to get accurate frame count for progress bar & allocation.
            fprintf('  - Compression detected. Scanning frames for accurate progress...\n');
            
            % Fast scan to count frames
            nFrames = 0;
            while true
                nFrames = nFrames + 1;
                if t.lastDirectory(), break; end
                t.nextDirectory();
            end
            t.setDirectory(1); % Rewind
            
            % Calculate "Disk Weight" per frame so progress sums to fileSize
            bytesPerReport = fileSize / nFrames;
            fprintf('  - Scanned %d frames.\n', nFrames);
        else
            % Uncompressed: Estimate is usually safe
            nFrames = floor(fileSize / bytesPerFrameRaw);
            if nFrames < 1, nFrames = 1; end
            
            % For uncompressed, raw size is close to disk size per frame
            bytesPerReport = bytesPerFrameRaw; 
        end
        
        fprintf('  - Dimensions: %d x %d, Frames: %d, Bit Depth: %d\n', W, H, nFrames, BitDepth);

        % Pre-allocate exact size (No more guessing/resizing)
        img = zeros(H, W, nFrames, 'single');
        maxVal = 2^BitDepth - 1;
        
        fprintf('Reading image stack... 0%%');
        last_percent_shown = 0;
        
        % Ensure we are at start
        if t.currentDirectory() ~= 1, t.setDirectory(1); end
        
        k = 0;
        while true
            k = k + 1;
            
            % Safety resize if file grew or estimate was wrong (unlikely now)
            if k > size(img, 3), img(:, :, k+10) = 0; end
            
            frame = t.read();
            if size(frame, 3) > 1, frame = mean(frame, 3); end
            
            if rescaleImg && ~isFloat
                img(:, :, k) = single(frame) / maxVal;
            else
                img(:, :, k) = single(frame);
            end
            
            % [FIX] Update Progress using the normalized value
            if isa(progressCallback, 'function_handle')
                progressCallback(bytesPerReport);
            end

            percent_done = floor(k / nFrames * 100);
            if percent_done >= last_percent_shown + 10
                fprintf('...%d%%', percent_done);
                last_percent_shown = percent_done;
            end
            
            if t.lastDirectory()
                break;
            else
                t.nextDirectory();
            end
        end
        
        % Final trim if needed
        if k < size(img, 3), img = img(:, :, 1:k); end
        
        fprintf('...100%% Done.\n');
        t.close();
        
    catch ME
        if exist('t', 'var'), t.close(); end
        rethrow(ME);
    end
    
else
    % --- STRATEGY B: Fread (Uncompressed & Contiguous) ---
    t.close();
    fprintf('File appears as a large, single-directory contiguous TIFF (Uncompressed).\n');
    
    try
        fid_temp = fopen(fName, 'r');
        header = fread(fid_temp, 2, 'uint8=>char')';
        fclose(fid_temp);
        
        if strcmp(header, 'II'), machineFormat = 'l'; else, machineFormat = 'b'; end

        bytesPerFrameRaw = W * H * (BitDepth / 8);
        nFrames = floor((fileSize - firstOffset(1)) / bytesPerFrameRaw);
        
        % Logic for bit depth precision...
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
        start_points = firstOffset(1) + (0:1:(nFrames-1)) * bytesPerFrameRaw;
        
        fprintf('Reading image stack... 0%%');
        last_percent_shown = 0;
        
        % For uncompressed fread, raw bytes match disk bytes closely enough
        bytesPerReport = bytesPerFrameRaw;

        for k = 1:nFrames
            fseek(fID, start_points(k), 'bof');
            frame_raw = fread(fID, [W H], precision);
            
            if numel(frame_raw) ~= (W*H)
                nFrames = k - 1; img = img(:,:,1:nFrames);
                break;
            end
            
            frame = frame_raw';
            
            if rescaleImg && ~isFloat
                img(:, :, k) = single(frame) / maxVal;
            else
                img(:, :, k) = single(frame);
            end
            
            if isa(progressCallback, 'function_handle')
                progressCallback(bytesPerReport);
            end

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