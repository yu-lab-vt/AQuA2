function datR = reconstructDatR(ov0,sz)
    datR = zeros(sz, 'uint8');
    for tt = 1:sz(4)
        ov00 = ov0.frame{tt};
        dRecon00 = zeros(sz(1:3));
        if isempty(ov00)
            continue
        end 
        for ii = 1:numel(ov00.idx)
            pix00 = ov00.pix{ii};
            val00 = ov00.val{ii};
            dRecon00(pix00) = uint8(val00 * 255);
        end 
        datR(:, :, :,tt) = dRecon00;
    end 
end