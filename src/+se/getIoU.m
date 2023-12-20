function iou = getIoU(pix1,pix2)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
    n1 = numel(intersect(pix1,pix2));
    n2 = numel(union(pix1,pix2));
    iou = n1/n2;
end