function [regions] = bw2Reg(BW,opts)
% ----------- Created by Xuelong Mi, 11/08/2022 -----------
    if isfield(opts,'spaMergeDist') && opts.spaMergeDist>0
        if size(BW,3) == 1
            BW2 = imdilate(BW,strel('disk',opts.spaMergeDist));
        else
            BW2 = imdilate(BW,strel('sphere',opts.spaMergeDist));
        end
        regions = bwconncomp(BW2).PixelIdxList;
        for i = 1:numel(regions)
            pix = regions{i};
            regions{i} = pix(BW(pix));
        end
        sz = cellfun(@numel,regions);
        regions = regions(sz>0);
    else
        regions = bwconncomp(BW).PixelIdxList;
    end
end