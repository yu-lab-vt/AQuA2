function c = calCC(a,b)
%     a = a - mean(a(:))-0.1;
%     b = b - mean(b(:))-0.1;
    [H,W,L] = size(a);
    a_add = zeros(2*H-1,2*W-1,2*L-1);
    b_add = a_add;
    a_add(1:H,1:W,1:L) = a;
    b_add(1:H,1:W,1:L) = flip(flip(flip(b,1),2),3);
    c = ifftn(fftn(a_add).*fftn(b_add));
end