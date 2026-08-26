function memberships = materializeCFUMemberships(memberships, evtLst, sz)
%MATERIALIZECFUMEMBERSHIPS Attach local x-y-z-t masks to CFU memberships.

    nSpatialPixels = prod(sz(1:3));
    for cfuIndex = 1:numel(memberships)
        membership = memberships{cfuIndex};
        voxelIndices = cell(1, numel(membership.EventID));
        for eventIndex = 1:numel(membership.EventID)
            eventVoxels = evtLst{membership.EventID(eventIndex)};
            eventSpatialPixels = mod(eventVoxels - 1, nSpatialPixels) + 1;
            voxelIndices{eventIndex} = eventVoxels(ismember(eventSpatialPixels, ...
                membership.SpatialPixels{eventIndex}));
        end
        membership.VoxelIndices = voxelIndices;
        memberships{cfuIndex} = membership;
    end
end
