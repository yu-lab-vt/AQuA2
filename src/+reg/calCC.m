function c = calCC(a,b)
%     a = a - mean(a(:))-0.1;
%     b = b - mean(b(:))-0.1;
    [H,W] = size(a);
    a_add = zeros(2*H-1,2*W-1);
    b_add = a_add;
    a_add(1:H,1:W) = a;
    b_add(1:H,1:W) = rot90(b,2);
    c = ifft2(fft2(a_add).*fft2(b_add));
end