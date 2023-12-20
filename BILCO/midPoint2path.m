function [path] = midPoint2path(curMidPoint,T1,T2)
% convert midPoint to path
    x = 0;
    y = 0;
    path = [];
    while(y<T1-1)
        ix = [x:floor(curMidPoint(y+1))]';
        iy = ones(numel(ix),1)*y;
        path = [path;ix,iy];
        x = floor(curMidPoint(y+1));
        if(curMidPoint(y+1)~=floor(curMidPoint(y+1)))
            x = x+1;
        end
        y = y+1;
    end
    ix = [x:T2-1]';
    iy = ones(numel(ix),1)*(T1-1);
    path = [path;ix,iy];
    path = [path(:,2),path(:,1)];
    path = path+1;
end

