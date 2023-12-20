function [correctMap2] = correctBoundaryStd(smo,sz)
% correct the variance in the boundary (caused by smoothing operation)
% Xuelong 02/02/2023
    H = sz(1); W = sz(2); L = sz(3);
    if numel(sz)<3
        L = 1;
    end
    dist = ceil(2*smo);
    filter0 = zeros(dist*2+1,dist*2+1,dist*2+1);
    filter0(dist+1,dist+1,dist+1) = 1;
    filter0 = imgaussfilt(filter0,smo);
    filter = filter0.^2;

    correctMap = zeros(size(filter0));
    for x = dist+1:2*dist+1
        for y = dist+1:2*dist+1
            for z = dist+1:2*dist+1
                filter1 = filter0;
                filter1(x,:,:) = sum(filter1(x:end,:,:),1);
                filter1(:,y,:) = sum(filter1(:,y:end,:),2);
                filter1(:,:,z) = sum(filter1(:,:,z:end),3);
                correctMap(x,y,z) = sqrt(sum(filter1(1:x,1:y,1:z).^2,[1,2,3])/sum(filter(:)));
            end
        end
    end
    correctMap = correctMap(1+dist:end,1+dist:end,1+dist:end);
    correctMap2 = zeros(H,W,L);
    [ih,iw,il] = ind2sub([H,W,L],1:H*W*L);

    % mapping to correctMap
    ih = min(min(ih,H-ih+1),dist+1);
    iw = min(min(iw,W-iw+1),dist+1);
    il = min(min(il,L-il+1),dist+1);
    correctMap2(:) = correctMap(sub2ind([dist+1,dist+1,dist+1],ih,iw,il));

    % in case dist+1 > H or W or L
    correctMap2 = correctMap2/min(correctMap2(:));
end