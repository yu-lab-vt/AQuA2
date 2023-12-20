function updtMskSld(~,~,f,rr)
    % update slider
    
    fh = guidata(f);
    
    [H,W,L] = size(rr.datAvg);
    
    fh.sldMskThr.Limits = [0,1];
    fh.sldMskThr.Value = double(rr.thr);
    
    fh.sldMskMinSz.Limits = [0,log10(H*W*L*1.1)];
    fh.sldMskMinSz.Value = log10(double(rr.minSz));
    
    fh.sldMskMaxSz.Limits = [0,log10(H*W*L*1.1)];
    fh.sldMskMaxSz.Value = log10(double(rr.maxSz));    
end
