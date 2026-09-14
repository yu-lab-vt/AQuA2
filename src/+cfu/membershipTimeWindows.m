function [ownTimeWindows, nonTimeWindows, overlappingCFUs] = ...
    membershipTimeWindows(memberships, cfuRegions, sz)
%MEMBERSHIPTIMEWINDOWS Build CFU curve windows from local event membership.
%   Unlike a single label volume, this representation preserves events that
%   legitimately belong to several CFUs.  ownTimeWindows marks frames where
%   a CFU's own local event mask is active.  nonTimeWindows marks activity
%   from spatially overlapping, other CFU memberships after own activity is
%   removed.  overlappingCFUs lists those other CFU indices.

    nCFU = numel(memberships);
    nSpatialPixels = prod(sz(1:3));
    nFrames = sz(4);
    ownTimeWindows = false(nCFU, nFrames);
    nonTimeWindows = false(nCFU, nFrames);
    overlappingCFUs = cell(nCFU, 1);
    primaryPixels = cell(nCFU, 1);

    for cfuIndex = 1:nCFU
        primaryPixels{cfuIndex} = find(cfuRegions{cfuIndex} > 0.1);
        membership = memberships{cfuIndex};
        for eventIndex = 1:numel(membership.VoxelIndices)
            ownTimeWindows(cfuIndex, framesFromVoxels( ...
                membership.VoxelIndices{eventIndex}, nSpatialPixels)) = true;
        end
    end

    for targetIndex = 1:nCFU
        targetPixels = primaryPixels{targetIndex};
        if isempty(targetPixels)
            continue;
        end
        for sourceIndex = 1:nCFU
            if sourceIndex == targetIndex
                continue;
            end
            membership = memberships{sourceIndex};
            sourceOverlaps = false;
            for eventIndex = 1:numel(membership.VoxelIndices)
                voxels = membership.VoxelIndices{eventIndex};
                spatialPixels = mod(voxels - 1, nSpatialPixels) + 1;
                localOverlap = ismember(spatialPixels, targetPixels);
                if ~any(localOverlap)
                    continue;
                end
                sourceOverlaps = true;
                nonTimeWindows(targetIndex, framesFromVoxels( ...
                    voxels(localOverlap), nSpatialPixels)) = true;
            end
            if sourceOverlaps
                overlappingCFUs{targetIndex}(end+1) = sourceIndex;
            end
        end
    end
    nonTimeWindows(ownTimeWindows) = false;
end

function frames = framesFromVoxels(voxels, nSpatialPixels)
    frames = unique(floor((double(voxels) - 1) / nSpatialPixels) + 1);
end
