function [img,bitDepth] = readAvi(fileName)
%READAVI Read a 2-D+t AVI file as a grayscale image sequence.

reader = VideoReader(fileName);
height = reader.Height;
width = reader.Width;
estimatedFrames = max(1,ceil(reader.Duration*reader.FrameRate));
img = zeros(height,width,estimatedFrames,'single');
frameIndex = 0;

while hasFrame(reader)
    frameIndex = frameIndex + 1;
    if frameIndex > size(img,3)
        img(:,:,frameIndex + max(100,ceil(0.1*estimatedFrames))) = 0;
    end

    frame = readFrame(reader);
    if ndims(frame) == 3
        frame = 0.2989*single(frame(:,:,1)) + ...
            0.5870*single(frame(:,:,2)) + 0.1140*single(frame(:,:,3));
    end
    if ~isequal(size(frame),[height,width])
        error('io:readAvi:FrameSizeMismatch', ...
            'AVI frame %d has unexpected dimensions in %s.',frameIndex,fileName);
    end
    img(:,:,frameIndex) = single(frame);

end

if frameIndex == 0
    error('io:readAvi:EmptyVideo','AVI file contains no frames: %s',fileName);
end
img = img(:,:,1:frameIndex);
bitDepth = 8;
end
