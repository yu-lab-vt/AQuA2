function startPoint = getPropagationStartPoint(res, evtIndex)
%GETPROPAGATIONSTARTPOINT Calculate event propagation start point
%   INPUTS:
%       res: AQuA result structure
%       evtIndex: Event index (1-based)
%
%   OUTPUT:
%       startPoint: [x, y] or [NaN, NaN] on failure

    startPoint = [NaN, NaN];
    
    % Validate input structure
    requiredFields = {'evt1', 'datOrg1', 'opts'};
    if ~all(isfield(res, requiredFields))
        return;
    end
    
    % Check event index validity
    if evtIndex < 1 || evtIndex > numel(res.evt1)
        return;
    end
    
    % Get data dimensions
    try
        H = res.opts.sz(1);
        W = res.opts.sz(2);
        T = res.opts.sz(4);
        totalPixels = H * W * T;  % L dimension unused in coordinates
    catch
        return;
    end
    
    % Extract and validate event pixels
    pix0 = res.evt1{evtIndex};
    if isempty(pix0)
        return;
    end
    
    % Filter invalid pixels
    validMask = pix0 >= 1 & pix0 <= totalPixels & isfinite(pix0);
    pix0 = pix0(validMask);
    if isempty(pix0)
        return;
    end
    
    % Convert to coordinates
    try
        [y, x, ~, t] = ind2sub([H, W, 1, T], pix0);  % L=1 for 3D compatibility
    catch
        return;
    end
    
    % Find earliest time point
    if isempty(t)
        return;
    end
    t0 = min(t);
    t0_mask = (t == t0);
    
    % Handle empty start frame case
    if ~any(t0_mask)
        t0 = min(t);
        t0_mask = (t == t0);
    end
    
    % Extract start frame pixels
    start_x = x(t0_mask);
    start_y = y(t0_mask);
    
    % Get intensity weights
    try
        weights = double(res.datOrg1(pix0(t0_mask)));
        if all(weights == 0)
            weights = ones(size(weights));  % Fallback to uniform weights
        end
    catch
        weights = ones(size(start_x));      % Default to uniform weights
    end
    
    % Calculate weighted centroid
    try
        sumWeights = sum(weights);
        weighted_x = sum(start_x .* weights) / sumWeights;
        weighted_y = sum(start_y .* weights) / sumWeights;
    catch
        weighted_x = mean(start_x);
        weighted_y = mean(start_y);
    end
    
    % Validate output coordinates
    if weighted_x >= 1 && weighted_x <= W && ...
       weighted_y >= 1 && weighted_y <= H
        startPoint = [weighted_x, weighted_y];
    else
        startPoint = [mean(start_x), mean(start_y)];  % Fallback to geometric mean
        % Final boundary check
        if any(startPoint < 1) || startPoint(1) > W || startPoint(2) > H
            startPoint = [NaN, NaN];
        end
    end
end

getPropagationStartPoint(res,1)