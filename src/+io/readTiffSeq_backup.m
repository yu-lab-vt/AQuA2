function [img,BitDepth] = readTiffSeq( fName, rescaleImg, progressCallback)
%READTIFF Read image sequence

if ~exist('rescaleImg','var')
    rescaleImg = 0;
end

info = imfinfo(fName);
BitDepth = info(1).BitDepth;
nFrames = numel(info);
maxVal = 2^(BitDepth)-1;
% change
H = info(1).Height;
W = info(1).Width;

% 07/08/2025 rewrite: only open the file one time
bytesPerFrame = H * W * (BitDepth/8);
% if isempty(fileSize)
%     fileSize = bytesPerFrame * nFrames; % estimates
% end

t = Tiff(fName, 'r');
img = zeros(H, W, nFrames, 'single');
for k = 1:nFrames
    t.setDirectory(k);
    frame = t.read();
    
    % multi-channel
    if size(frame, 3) > 1
        frame = mean(frame, 3);  % single channel
    end
    
    % scaling
    if rescaleImg
        frame = single(frame) / maxVal;
    else
        frame = single(frame);
    end
    
    img(:, :, k) = frame;
    
    if exist('progressCallback','var') && isa(progressCallback, 'function_handle')
        progressCallback(bytesPerFrame);
    end
end
t.close();  % 关闭文件

% if(numel(info)>1)
%     nChannel = info(1).SamplesPerPixel;
%     % [nRow,nCol] = size(oneFrame);
%     img = zeros(H, W, nFrames, 'single');
%     for k = 1:nFrames
%         oneFrame = imread(fName, k);
%         if(nChannel>1)
%             oneFrame = mean(oneFrame,3);
%         end
%         if rescaleImg
%             img(:,:,k) = single(oneFrame)/maxVal;
%         else
%             img(:,:,k) = oneFrame;
%         end
%     end
% else
%     T = floor(info.FileSize/info.StripByteCounts);
%     img = zeros(H, W, T, 'single');
%     start_point = info.StripOffsets(1) + (0:1:(T-1)).*info.StripByteCounts;
%     fID = fopen (fName, 'r');
%     for k = 1:T
%         fseek (fID, start_point(k), 'bof');
%         if info.BitDepth==32
%             A = fread(fID, [H W], 'uint32=>uint32');
%         elseif info.BitDepth==16
%             A = fread(fID, [H W], 'uint16=>uint16');
%         else
%             A = fread(fID, [H W], 'uint8=>uint8');
%         end
% 
%         img(:,:,k) = A';
%     end
%     fclose(fID);
% end

end

