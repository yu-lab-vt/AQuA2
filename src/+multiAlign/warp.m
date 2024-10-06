function input = warp(input,tform,ref,x0,x1,y0,y1)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
    input = imwarp(input, tform, 'OutputView', imref2d(size(ref)));
    input = input(x0:x1, y0:y1, :, :);
end