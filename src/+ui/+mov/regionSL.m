function regionSL(~,~,f,op,lbl)
    bd = getappdata(f,'bd');
    opts = getappdata(f,'opts');
    
    if strcmp(op,'save')
        if strcmp(lbl,'cell')
            definput = {'_Cell.mat'};
            selname = inputdlg('Type desired suffix for Region file:',...
                'Region file',[1 75],definput);

            selname = char(selname);
            if isempty(selname)
                return;
            end
        else
            definput = {'_LandMark.mat'};
            selname = inputdlg('Type desired suffix for Region file:',...
                'Region file',[1 75],definput);

            selname = char(selname);
            if isempty(selname)
                return;
            end
        end
        file0 = [opts.fileName1,selname];
        clear definput selname

        %file0 = [opts.fileName,'_AQuA']; SP, 18.07.16
        selpath = uigetdir(opts.filePath1,'Choose output folder');
        path0 = [selpath,filesep,file0];
        if ~isnumeric(selpath)
            if bd.isKey(lbl)
                bd0 = bd(lbl);
            else
                bd0 = [];
            end
            save(path0,'bd0');
        end
    else
       [file,path] = uigetfile({'*.mat;*.zip'},'Choose Region file',opts.filePath1); 
       if ~isnumeric([path,file])
           [~,~,ext] = fileparts(file);
           if(strcmp(ext,'.mat'))
               loadContent = load([path,file],'bd0');
               bd(lbl) = loadContent.bd0;
               setappdata(f,'bd',bd);
               ui.movStep(f,[],[],1);
           else
               prompt = {'Pixel number of growing ROIs (0: no grow):'};
               dlgtitle = 'Input';
               dims = [1 60];
               definput = {'0'};
               answer = inputdlg(prompt,dlgtitle,dims,definput);
               if(isempty(answer)) return; end
               nGrow = round(str2double(answer{1}));
       
               [cvsROI] = ReadImageJROI([path,file]);
               H = opts.sz(1)+2*opts.regMaskGap;
               W = opts.sz(2)+2*opts.regMaskGap;
               [sRegions] = ROIs2Regions(cvsROI, [W,H]);
               ROIinfo0 = cell(numel(sRegions.PixelIdxList),1);
               if bd.isKey(lbl)
                    bd0 = bd(lbl);
               else
                    bd0 = [];
               end
               if bd.isKey('roi')
                    ROIinfo = bd('roi');
               else
                    ROIinfo = cell(0,1);
               end
               bd00 = cell(numel(sRegions.PixelIdxList),1);
               nBd = numel(bd0);
               if(nBd==0) bd0 = cell(0,1); end;
               for i = 1:numel(sRegions.PixelIdxList)
                   pix = sRegions.PixelIdxList{i};
                   [iw,ih] = ind2sub([W,H],pix);
                   ih = ih - opts.regMaskGap;
                   iw = iw - opts.regMaskGap;
                   select = ih>0 & iw>0 & ih<=opts.sz(1) & iw<=opts.sz(2);
                   pix = sub2ind(opts.sz(1:2),ih(select),iw(select));
                   
                   pix = growRegion(pix,opts.sz(1:2),nGrow);
                   msk = false(opts.sz(1:2));
                   msk(pix) = true;
                   tmp{1} = bwboundaries(msk);
                   tmp{2} = pix;
                   tmp{3} = 'manual';
                   tmp{4} = 'None';
                   bd00{i} = tmp;
                   ROIinfo0{i}.pix = pix;
                   ROIinfo0{i}.name = num2str(nBd+i);
               end
               
               bd0(nBd + 1:nBd + numel(bd00)) = bd00;
               bd(lbl) = bd0;
               nRoi = numel(ROIinfo);
               ROIinfo(nRoi + 1:nRoi + numel(ROIinfo0)) = ROIinfo0;
               bd('roi') = ROIinfo;
               setappdata(f,'bd',bd);
               ui.movStep(f,[],[],1);
           end
       end
    end 
end
function pixGrow = growRegion(pix,sz,nGrow)
    if(nGrow <= 0)
        pixGrow = pix;
        return;
    end
    H = sz(1);
    W = sz(2);
    dh = [-1,0,1,-1,1,-1,0,1];
    dw = [-1,-1,-1,0,0,1,1,1];
    
    newCandidate = pix;
    pixGrow = pix;
    for k = 1:nGrow
        [ih0,iw0] = ind2sub([H,W],newCandidate);
        newCandidate = [];
        for i = 1:numel(dw)
           ih = max(1,min(H,ih0+dh(i)));
           iw = max(1,min(W,iw0+dw(i)));
           newIhw = sub2ind([H,W],ih,iw);
           newCandidate = [newCandidate;newIhw];
        end
        newCandidate = setdiff(newCandidate,pixGrow);
        pixGrow = [pixGrow;newCandidate];
    end
    
end