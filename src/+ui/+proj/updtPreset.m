function updtPreset(~,~,f,readTb)
    
    fh = guidata(f);
    
    if ~exist('readTb','var')
        readTb = 1;
    end
    
    if readTb>0
        cfgFile = 'parameters.csv';
        cfg = readtable(cfgFile,'PreserveVariableNames',true);
        cNames = cfg.Properties.VariableNames(4:end-1);
        fh.preset.Items = cNames;
    end
    
    preset = find(strcmp(fh.preset.Items,fh.preset.Value));
    opts = util.parseParam(preset);
    
    if isfield(opts,'frameRate') && ~isempty(opts.frameRate)
        fh.tmpRes.Value = num2str(opts.frameRate);
    end
    if isfield(opts,'spatialRes') && ~isempty(opts.spatialRes)
        fh.spaRes.Value = num2str(opts.spatialRes);
    end
    if isfield(opts,'regMaskGap') && ~isempty(opts.regMaskGap)
        fh.bdSpa.Value = num2str(opts.regMaskGap);
    end    
    
end