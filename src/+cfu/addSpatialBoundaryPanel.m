function addSpatialBoundaryPanel(fCFU, panelHost)
%addSpatialBoundaryPanel Add 2-D spatial classification controls to the CFU GUI.

    if ~isgraphics(fCFU) || ~isgraphics(panelHost)
        return;
    end

    delete(panelHost.Children);
    panelHost.Title = 'Spatial Polyline Classification';
    panelHost.Visible = 'on';

    grid = uigridlayout(panelHost, [4, 2], ...
        'ColumnWidth', {130, '1x'}, 'RowHeight', {20, 22, 22, 22}, ...
        'Padding', [10, 8, 10, 8], 'RowSpacing', 5, 'ColumnSpacing', 5);
    instruction = uilabel(grid, 'Text', 'Start at the left edge; right-click to cancel.');
    instruction.Layout.Column = [1, 2];
    uilabel(grid, 'Text', 'Upper class (A) label');
    editA = uieditfield(grid, 'numeric', 'Value', 0);
    uilabel(grid, 'Text', 'Lower class (B) label');
    editB = uieditfield(grid, 'numeric', 'Value', 1);
    button = uibutton(grid, 'push', 'Text', 'Draw boundary and classify', ...
        'Tag', 'spatialBoundaryButton', 'Enable', 'off', ...
        'ButtonPushedFcn', @(src, ~) cfu.drawSpatialBoundary(src, fCFU, editA, editB));
    button.Layout.Column = [1, 2];
end
