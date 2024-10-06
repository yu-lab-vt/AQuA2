function [x0, x1, y0, y1] = maximalRectangle(A)
    [n, m] = size(A);  
    heights = zeros(1, m);  
    maxArea = 0; 
    optimal = [-1,-1,-1,-1];
    for i = 1:n
        % 更新高度数组
        for j = 1:m
            if A(i, j) == 1
                heights(j) = heights(j) + 1;  
            else
                heights(j) = 0;  
            end
        end

        [maxArea0,optimal0] = largestRectangleArea(heights);
        if maxArea0 > maxArea
            maxArea = maxArea0;
            optimal = [i, optimal0];
        end
    end
    x0 = optimal(1) - optimal(3) + 1;
    y0 = optimal(2) - optimal(4) + 1;
    x1 = optimal(1);
    y1 = optimal(2);
end


function [maxArea,optimal] = largestRectangleArea(heights)
    heights = [heights, 0];  
    stack = [];  
    maxArea = 0;
    optimal = [-1,-1,-1];
    for i = 1:length(heights)
        while ~isempty(stack) && heights(stack(end)) > heights(i)
            h = heights(stack(end));
            stack(end) = [];  
            if isempty(stack)
                width = i - 1;
            else
                width = i - stack(end) - 1;
            end
            if h*width > maxArea
                maxArea = h * width;
                optimal = [i - 1, h, width];
            end
        end
        stack = [stack, i]; 
    end
end