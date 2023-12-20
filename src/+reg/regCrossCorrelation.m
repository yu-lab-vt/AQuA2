function [data1,data2] = regCrossCorrelation(data1,data2)
% convert to 3D version
    ref = mean(data1(:,:,:,1:10),4); % first 10 frames as reference
    ref = ref - median(ref(:)); % align bright part. Remove median is like remove background
    [H,W,L,T] = size(data1);
    x_translation = zeros(1,T);
    y_translation = zeros(1,T);
    z_translation = zeros(1,T);
    
    % concise cross correlation
    parfor t = 1:T
        moving = data1(:,:,:,t);
        moving = moving - median(moving(:));
        matrix = calCC(moving,ref);
        [~,id] = max(matrix(:));
        [hShift,wShift,lShift] = ind2sub(size(matrix),id); 
        x_translation(t) = H-hShift;
        y_translation(t) = W-wShift;
        z_translation(t) = L-lShift;
    end

    for t = 1:T 
        if x_translation(t)>=0
            xs0 = 1; xe0 = H-x_translation(t);
            xs1 = 1+x_translation(t); xe1 = H;
        else
            xs0 = 1-x_translation(t); xe0 = H;
            xs1 = 1; xe1 = H+x_translation(t);
        end
        if y_translation(t)>=0
            ys0 = 1; ye0 = W-y_translation(t);
            ys1 = 1+y_translation(t); ye1 = W;
        else
            ys0 = 1-y_translation(t); ye0 = W;
            ys1 = 1; ye1 = W+y_translation(t);
        end
        if z_translation(t)>=0
            zs0 = 1; ze0 = L-z_translation(t);
            zs1 = 1+z_translation(t); ze1 = L;
        else
            zs0 = 1-z_translation(t); ze0 = L;
            zs1 = 1; ze1 = L+z_translation(t);
        end  
        data1(xs1:xe1,ys1:ye1,zs1:ze1,t) = data1(xs0:xe0,ys0:ye0,zs0:ze0,t);
        if(~isempty(data2))
            data2(xs1:xe1,ys1:ye1,zs1:ze1,t) = data2(xs0:xe0,ys0:ye0,zs0:ze0,t);
        end
    end
    data1 = data1(max(x_translation)+1:end+min(x_translation),max(y_translation)+1:end+min(y_translation),max(z_translation)+1:end+min(z_translation),:);
    if(~isempty(data2))
        data2 = data2(max(x_translation)+1:end+min(x_translation),max(y_translation)+1:end+min(y_translation),max(z_translation)+1:end+min(z_translation),:);
    end
end