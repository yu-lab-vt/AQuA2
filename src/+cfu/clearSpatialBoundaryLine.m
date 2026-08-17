function clearSpatialBoundaryLine(fCFU)
%clearSpatialBoundaryLine Remove the graphics handle for a saved boundary.

    if ~isappdata(fCFU, 'spatialBoundaryLine')
        return;
    end
    boundaryLine = getappdata(fCFU, 'spatialBoundaryLine');
    if isgraphics(boundaryLine)
        delete(boundaryLine);
    end
    rmappdata(fCFU, 'spatialBoundaryLine');
end
