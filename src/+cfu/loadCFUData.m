% 08/27/2025 added: load CFU data

function loadCFUData(~, ~, fCFU, fOut)
    % Open file chooser
    [filename, pathname] = uigetfile('*.mat', 'Select CFU Data File');
    if isequal(filename, 0)
        return; % User cancelled
    end

    % Load .mat file
    fullpath = fullfile(pathname, filename);
    try
        loadedData = load(fullpath);

        % Required fields according to the format produced by output.m/CFU pipeline
        requiredFields = {'cfuInfo1', 'cfuOpts'};
        opts = getappdata(fOut, 'opts');

        % Validate basic structure
        hasAllFields = all(isfield(loadedData, requiredFields));
        if ~hasAllFields
            errordlg('Selected file does not contain valid CFU data.', 'Invalid File');
            return;
        end

        % Get GUI handle struct
        fh = guidata(fCFU);

        % Store loaded data into app data
        fh.pThr.Enable = 'off';
        fh.minNumCFU.Enable = 'off';
        fh.buttonGroup.Enable = 'off';
        setappdata(fCFU, 'cfuInfo1', loadedData.cfuInfo1);
        if isfield(loadedData, 'cfuInfo2')
            setappdata(fCFU, 'cfuInfo2', loadedData.cfuInfo2);
            fh.pThr.Enable = 'on';
            fh.minNumCFU.Enable = 'on';
            fh.buttonGroup.Enable = 'on';
        else
            % Ensure old appdata are cleared if file does not contain channel 2
            if isappdata(fCFU, 'cfuInfo2'); rmappdata(fCFU, 'cfuInfo2'); end
        end

        if isfield(loadedData, 'cfuRelation')
            setappdata(fCFU, 'relation', loadedData.cfuRelation);

        else
            if isappdata(fCFU, 'relation'); rmappdata(fCFU, 'relation'); end
        end

        if isfield(loadedData, 'cfuGroupInfo')
            setappdata(fCFU, 'groupInfo', loadedData.cfuGroupInfo);
        else
            if isappdata(fCFU, 'groupInfo'); rmappdata(fCFU, 'groupInfo'); end
        end

        % Rebuild cfuMap1 from cfuInfo1 (same convention as in CFURunGui)
        % cfuInfo{i,3} stores the weightMap of CFU i
        cfuInfo1 = loadedData.cfuInfo1;
        nCFU1 = size(cfuInfo1, 1);

        % Determine data size H,W,L from opts
        if isempty(opts) || ~isfield(opts, 'sz') || numel(opts.sz) < 3
            error('opts.sz is missing or invalid.');
        end
        H = opts.sz(1); W = opts.sz(2); L = opts.sz(3);

        % Build cfuMap1
        cfuMap1 = zeros(H, W, L, 'uint16');
        for i = 1:nCFU1
            weightMap = cfuInfo1{i,3};
            % Accept both vectorized and 3D matrix weight maps
            if numel(weightMap) == H*W*L
                weightMap = reshape(weightMap, [H, W, L]);
            elseif ~isequal(size(weightMap), [H, W, L])
                error('cfuInfo1{%d,3} has incompatible size.', i);
            end
            cfuMap1(weightMap > 0.1) = uint16(i);
        end
        fh.cfuMap1 = cfuMap1;

        % Build downsampled cfuMapDS1 (same logic as CFURunGui)
        dsSclXY = fh.sldDsXY.Value;
        DataDs = se.myResize(zeros(opts.sz(1:3), 'single'), 1/dsSclXY);
        overlayLabelDs1 = zeros(size(DataDs), 'uint16');
        cfuShow1 = label2idx(fh.cfuMap1);
        for i = 1:numel(cfuShow1)
            if ~isempty(cfuShow1{i})
                [ih, iw, il] = ind2sub([H, W, L], cfuShow1{i});
                pix0 = unique(sub2ind(size(DataDs), ceil(ih/dsSclXY), ceil(iw/dsSclXY), il));
                overlayLabelDs1(pix0) = uint16(i);
            end
        end
        fh.cfuMapDS1 = overlayLabelDs1;

        % If channel 2 exists, rebuild cfuMap2 and cfuMapDS2 similarly
        if isfield(loadedData, 'cfuInfo2') && ~isempty(loadedData.cfuInfo2)
            cfuInfo2 = loadedData.cfuInfo2;
            nCFU2 = size(cfuInfo2, 1);

            cfuMap2 = zeros(H, W, L, 'uint16');
            for i = 1:nCFU2
                weightMap = cfuInfo2{i,3};
                if numel(weightMap) == H*W*L
                    weightMap = reshape(weightMap, [H, W, L]);
                elseif ~isequal(size(weightMap), [H, W, L])
                    error('cfuInfo2{%d,3} has incompatible size.', i);
                end
                cfuMap2(weightMap > 0.1) = uint16(i);
            end
            fh.cfuMap2 = cfuMap2;

            DataDs = se.myResize(zeros(opts.sz(1:3), 'single'), 1/dsSclXY);
            overlayLabelDs2 = zeros(size(DataDs), 'uint16');
            cfuShow2 = label2idx(fh.cfuMap2);
            for i = 1:numel(cfuShow2)
                if ~isempty(cfuShow2{i})
                    [ih, iw, il] = ind2sub([H, W, L], cfuShow2{i});
                    pix0 = unique(sub2ind(size(DataDs), ceil(ih/dsSclXY), ceil(iw/dsSclXY), il));
                    overlayLabelDs2(pix0) = uint16(i);
                end
            end
            fh.cfuMapDS2 = overlayLabelDs2;
        else
            % Clear channel 2 maps if not provided
            if isfield(fh, 'cfuMap2'); fh = rmfield(fh, 'cfuMap2'); end
            if isfield(fh, 'cfuMapDS2'); fh = rmfield(fh, 'cfuMapDS2'); end
        end

        % Enable/disable related controls to match CFURunGui after computation
        fh.pickButton.Enable   = 'on';
        fh.viewButton.Enable   = 'on';
        fh.addAllButton.Enable = 'on';
        fh.calDep.Enable       = 'on';
        fh.winSz.Enable        = 'on';
        fh.sldWinSz.Enable     = 'on';
        fh.shift.Enable        = 'on';

        % Show tool panel
        fh.pTool1.Visible = 'on';

        % Initialize favorites list
        fh.favCFUs = [];
        fh.selectCFUs = [];
        fh.groupShow = 0;
        fh.delayMode = false;

        % Group-related controls if relation info exists
        if isfield(loadedData, 'cfuRelation')
            fh.pThr.Enable       = 'on';
            fh.minNumCFU.Enable  = 'on';
            fh.buttonGroup.Enable= 'on';
        else
            fh.pThr.Enable       = 'off';
            fh.minNumCFU.Enable  = 'off';
            fh.buttonGroup.Enable= 'off';
        end

        % If group info exists, refresh group table
        if isfield(loadedData, 'cfuGroupInfo')
            cfu.updtGrpTable(fCFU, fOut);
        end

        % Restore Parameters from cfuOpts (Added Fix 2025/12/02)
        if isfield(loadedData, 'cfuOpts')
            optsLoaded = loadedData.cfuOpts;

            % 1. Detection Parameters
            if isfield(optsLoaded, 'cfuDetect')
                det = optsLoaded.cfuDetect;
                % Channel 1
                if isfield(det, 'overlapThr1')
                    fh.alpha.Value = num2str(det.overlapThr1);
                end
                if isfield(det, 'minNumEvt1')
                    fh.minNumEvt.Value = num2str(det.minNumEvt1);
                end
                
                % Channel 2
                if isfield(fh, 'alpha2') && isfield(det, 'overlapThr2')
                     fh.alpha2.Value = num2str(det.overlapThr2);
                end
                if isfield(fh, 'minNumEvt2') && isfield(det, 'minNumEvt2')
                     fh.minNumEvt2.Value = num2str(det.minNumEvt2);
                end
            end

            % 2. Analysis Parameters
            if isfield(optsLoaded, 'cfuAnalysis')
                ana = optsLoaded.cfuAnalysis;
                if isfield(ana, 'maxDist')
                    currentMax = fh.sldWinSz.Limits(2);
                    if ana.maxDist > currentMax
                        fh.sldWinSz.Limits(2) = ana.maxDist * 1.5;
                    end
                    fh.sldWinSz.Value = ana.maxDist;
                    fh.winSz.Value = num2str(ana.maxDist);
                end
                if isfield(ana, 'shift')
                    fh.shift.Value = num2str(ana.shift);
                end
            end

            % 3. Group Parameters
            if isfield(optsLoaded, 'cfuGroup')
                grp = optsLoaded.cfuGroup;
                if isfield(grp, 'pValueThr')
                    fh.pThr.Value = num2str(grp.pValueThr);
                end
                if isfield(grp, 'cfuNumThr')
                    fh.minNumCFU.Value = num2str(grp.cfuNumThr);
                end
            end
        end

        % Persist GUI data
        guidata(fCFU, fh);
        cfu.updtCFUTable(fCFU);
        ui.updtCFUint([], [], fCFU, true);

    catch ME
        errordlg(sprintf('Error loading file: %s', ME.message), 'Load Error');
    end
end