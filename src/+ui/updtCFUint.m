function updtCFUint(~,~,fCFU,colorRenew)
    % use btSt.sbs, btSt.leftView and btSt.rightView to determine what to show
    fh = guidata(fCFU);
    opts = fh.opts;
    if opts.sz(3)==1
        % 2D
        dat1 = fh.averPro1;
        [H,W] = size(dat1);
        dat1 = dat1 - min(dat1(:));
        dat1 = dat1/max(dat1(:));
        dat1 = dat1*fh.sldBk.Value;
        dat1 = cat(3,dat1,dat1,dat1);
        
        if(~opts.singleChannel)
            dat2 = fh.averPro2;
            dat2 = dat2 - min(dat2(:));
            dat2 = dat2/max(dat2(:));
            dat2 = dat2*fh.sldBk.Value;
            dat2 = cat(3,dat2,dat2,dat2);
        else
            dat2 = [];
        end
        
        cfuInfo1 = getappdata(fCFU,'cfuInfo1');
        cfuInfo2 = getappdata(fCFU,'cfuInfo2');
        nCFU1 = size(cfuInfo1,1);nCFU2 = size(cfuInfo2,1);
        if(~isempty(cfuInfo1))
            if(colorRenew)
                ff = waitbar(0,'Updating');
                cols1 = zeros(nCFU1,3); cols2 = zeros(nCFU2,3);
                colorMap1 = zeros(size(dat1)); colorMap2 = zeros(size(dat2));
                for i = 1:nCFU1
                    waitbar(i/nCFU1,ff);
                    x = randi(255,[1,3]);
                    while (x(1)>0.8*255 && x(2)>0.8*255 && x(3)>0.8*255) || sum(x)<255
                        x = randi(255,[1,3]);
                    end
                    cols1(i,:) = x;
                    curRegion = cfuInfo1{i,3};
                    colorMap1 = colorMap1 + cat(3,curRegion*x(1),curRegion*x(2),curRegion*x(3))/255;
                end
                for i = 1:nCFU2
                    waitbar(i/nCFU2,ff);
                    x = randi(255,[1,3]);
                    while (x(1)>0.8*255 && x(2)>0.8*255 && x(3)>0.8*255) || sum(x)<255
                        x = randi(255,[1,3]);
                    end
                    cols2(i,:) = x;
                    curRegion = cfuInfo2{i,3};
                    colorMap2 = colorMap2 + cat(3,curRegion*x(1),curRegion*x(2),curRegion*x(3))/255;
                end
                delete(ff);
                setappdata(fCFU,'cols1',cols1);
                setappdata(fCFU,'colorMap1',colorMap1);
                setappdata(fCFU,'cols2',cols2);
                setappdata(fCFU,'colorMap2',colorMap2);
            else
                cols1 = getappdata(fCFU,'cols1');
                colorMap1 = getappdata(fCFU,'colorMap1');
                cols2 = getappdata(fCFU,'cols2');
                colorMap2 = getappdata(fCFU,'colorMap2');
            end
        else
            colorMap1 = 0;
            colorMap2 = 0;
        end
        
        if(fh.groupShow>0)
            colorMap1 = zeros(size(dat1));
            colorMap2 = zeros(size(dat1));
            groupInfo = getappdata(fCFU,'groupInfo');
            groupCFUs = groupInfo{fh.groupShow,2};
            
            if(fh.delayMode)
                cols1 = zeros(nCFU1,3);
                cols2 = zeros(nCFU2,3);
                colorAssign = parula(256);
                relativeDelay = groupInfo{fh.groupShow,3};
                minDelay = min(relativeDelay);
                maxDelay = max(relativeDelay);
                group1 = groupCFUs(groupCFUs<=nCFU1);
                group2 = groupCFUs(groupCFUs>nCFU1)-nCFU1;
                colorId = round((relativeDelay-minDelay)/(maxDelay-minDelay)*255+1);
                colorId(isnan(colorId)) = 128;
                cols1(group1,:) = colorAssign(colorId(groupCFUs<=nCFU1),:)*255;
                cols2(group2,:) = colorAssign(colorId(groupCFUs>nCFU1),:)*255;
            end

            for i = 1:numel(groupCFUs)
                id = groupCFUs(i);
                if(id<=nCFU1)
                    x = cols1(id,:);
                    curRegion = cfuInfo1{id,3};
                    colorMap1 = colorMap1 + cat(3,curRegion*x(1),curRegion*x(2),curRegion*x(3))/255;
                else
                    id = id - nCFU1;
                    x = cols2(id,:);
                    curRegion = cfuInfo2{id,3};
                    colorMap2 = colorMap2 + cat(3,curRegion*x(1),curRegion*x(2),curRegion*x(3))/255;
                end
                
            end
        end
        
        %% add boundary 
        % clean all patches only when refreshing the view
        if(opts.singleChannel)
            axNow = fh.mov;
            types = {'patch','text','line'};
            for ii=1:numel(types)
                h00 = findobj(axNow,'Type',types{ii});
                if ~isempty(h00)
                    delete(h00);
                end
            end
            
            favLst = fh.favCFUs;
            for ii=1:numel(favLst)
                id = favLst(ii);
                pix = find(cfuInfo1{id,3}>0.1);
                xyC = img.getEventBorder({pix},[H,W,1,1]);
                xyC = xyC{1};
                x0 = 0;
                y0 = 0;
                for jj=1:numel(xyC)
                    xy = xyC{jj};
                    x0 = max(x0,max(xy(:,2)));
                    y0 = max(y0,max(H-xy(:,1)));
                    patch(axNow,'XData',xy(:,2),'YData',H-xy(:,1)+1,...
                        'FaceColor','none','EdgeColor',[1 0.85 0]*0.8,'LineWidth',1);
                end
                if x0 + 20>W
                    x0 = x0 - 20;
                end
                if y0 + 20>H
                    y0 = y0 - 20;
                end
                text(axNow,x0,y0,num2str(id),'Color',[1 0.85 0],'FontSize',20);
            end


            selectCFUs = fh.selectCFUs;
            for ii=1:size(selectCFUs,1)
                pix = find(cfuInfo1{selectCFUs(ii,2),3}>0.1);
                xyC = img.getEventBorder({pix},[H,W,1,1]);
                xyC = xyC{1};
                x0 = 0;
                y0 = 0;
                for jj=1:numel(xyC)
                    xy = xyC{jj};
                    x0 = max(x0,max(xy(:,2)));
                    y0 = max(y0,max(H-xy(:,1)));
                    patch(axNow,'XData',xy(:,2),'YData',H-xy(:,1)+1,...
                        'FaceColor','none','EdgeColor',[1 0.5 0.5]*0.8,'LineWidth',1);
                end
                if x0 + 20>W
                    x0 = x0 - 20;
                end
                if y0 + 20>H
                    y0 = y0 - 20;
                end
                text(axNow,x0,y0,num2str(selectCFUs(ii,2)),'Color',[1 0.5 0.5],'FontSize',20);
            end
            % overlay
            fh.ims.im1.CData = flipud(dat1 + colorMap1*fh.sldCol.Value);
        else
            favLst = fh.favCFUs;
            types = {'patch','text','line'};
            ax1 = fh.movL; ax2 = fh.movR;
            for ii=1:numel(types)
                h00 = findobj(ax1,'Type',types{ii});
                if ~isempty(h00)
                    delete(h00);
                end
                h00 = findobj(ax2,'Type',types{ii});
                if ~isempty(h00)
                    delete(h00);
                end
            end
            
            nCFU1 = size(cfuInfo1,1);
            for ii=1:numel(favLst)
                id = favLst(ii);
                if id>nCFU1
                    ax = ax2;
                    id = id - nCFU1;
                    pix = find(cfuInfo2{id,3}>0.1);
                else
                    ax = ax1;
                    pix = find(cfuInfo1{id,3}>0.1);
                end
                xyC = img.getEventBorder({pix},[H,W,1,1]);
                xyC = xyC{1};
                x0 = 0;
                y0 = 0;
                for jj=1:numel(xyC)
                    xy = xyC{jj};
                    x0 = max(x0,max(xy(:,2)));
                    y0 = max(y0,max(H-xy(:,1)));
                    patch(ax,'XData',xy(:,2),'YData',H-xy(:,1)+1,...
                        'FaceColor','none','EdgeColor',[1 0.85 0],'LineWidth',1);
                end
                if x0 + 20>W
                    x0 = x0 - 20;
                end
                if y0 + 20>H
                    y0 = y0 - 20;
                end
                text(ax,x0,y0,num2str(id),'Color',[1 0.85 0],'FontSize',20);
            end

            selectCFUs = fh.selectCFUs;
            for ii=1:size(selectCFUs,1)
                if(selectCFUs(ii,1)==1)
                    pix = find(cfuInfo1{selectCFUs(ii,2),3}>0.1);
                    ax = ax1;
                else
                    pix = find(cfuInfo2{selectCFUs(ii,2),3}>0.1);
                    ax = ax2;
                end
                xyC = img.getEventBorder({pix},[H,W,1,1]);
                xyC = xyC{1};
                x0 = 0;
                y0 = 0;
                for jj=1:numel(xyC)
                    xy = xyC{jj};
                    x0 = max(x0,max(xy(:,2)));
                    y0 = max(y0,max(H-xy(:,1)));
                    patch(ax,'XData',xy(:,2),'YData',H-xy(:,1)+1,...
                        'FaceColor','none','EdgeColor',[1 0.5 0.5],'LineWidth',1);
                end
                if x0 + 20>W
                    x0 = x0 - 20;
                end
                if y0 + 20>H
                    y0 = y0 - 20;
                end
                text(ax,x0,y0,num2str(selectCFUs(ii,2)),'Color',[1 0.5 0.5],'FontSize',20);
            end
            
            % overlay
            fh.ims.im2a.CData = flipud(dat1 + colorMap1*fh.sldCol.Value);
            fh.ims.im2b.CData = flipud(dat2 + colorMap2*fh.sldCol.Value);
        end
    else
        dat1 = fh.averPro1;
        [H,W,L] = size(dat1);
        dat1 = dat1 - min(dat1(:));
        dat1 = dat1/max(dat1(:));
        sclXY = fh.sldDsXY.Value;
        dat1 = se.myResize(dat1,1/sclXY);
        
        if(~opts.singleChannel)
            dat2 = fh.averPro2;
            dat2 = dat2 - min(dat2(:));
            dat2 = dat2/max(dat2(:));
            dat2 = se.myResize(dat2,1/sclXY);
        else
            dat2 = [];
        end
        dat = cell(1,2); dat{1} = dat1; dat{2} = dat2;
        
        cfuInfo1 = getappdata(fCFU,'cfuInfo1');
        cfuInfo2 = getappdata(fCFU,'cfuInfo2');
        nCFU1 = size(cfuInfo1,1);   nCFU2 = size(cfuInfo2,1);
        if(~isempty(cfuInfo1) || ~isempty(cfuInfo2))
            if(colorRenew)
                ff = waitbar(0,'Updating');
                cols1 = zeros(nCFU1,3); cols2 = zeros(nCFU2,3);
                for i = 1:nCFU1
                    waitbar(i/nCFU1,ff);
                    x = randi(255,[1,3]);
                    while (x(1)>0.8*255 && x(2)>0.8*255 && x(3)>0.8*255) || sum(x)<255
                        x = randi(255,[1,3]);
                    end
                    cols1(i,:) = x;
                end
                for i = 1:nCFU2
                    waitbar(i/nCFU2,ff);
                    x = randi(255,[1,3]);
                    while (x(1)>0.8*255 && x(2)>0.8*255 && x(3)>0.8*255) || sum(x)<255
                        x = randi(255,[1,3]);
                    end
                    cols2(i,:) = x;
                end
                delete(ff);
                setappdata(fCFU,'cols1',cols1);
                setappdata(fCFU,'cols2',cols2);
            else
                cols1 = getappdata(fCFU,'cols1');
                cols2 = getappdata(fCFU,'cols2');
            end
        else
            cols1 = [];
            cols2 = [];
        end
        
        if isfield(fh,'cfuMapDS1')
            overlayLabel1 = fh.cfuMapDS1;
        else
            overlayLabel1 = zeros(size(dat1));
        end

        if isfield(fh,'cfuMapDS2')
            overlayLabel2 = fh.cfuMapDS2;
        else
            overlayLabel2 = zeros(size(dat1));
        end

        if(fh.groupShow>0)
            groupInfo = getappdata(fCFU,'groupInfo');
            groupCFUs = groupInfo{fh.groupShow,2};
            overlayLabel1 = zeros(size(dat1),'uint16');
            if ~opts.singleChannel
                overlayLabel2 = zeros(size(dat1),'uint16');
            end
            cols = [cols1;cols2];
            groupCol = cols(groupCFUs,:);
            if(fh.delayMode)
                colorAssign = parula(256);
                relativeDelay = groupInfo{fh.groupShow,3};
                minDelay = min(relativeDelay);
                maxDelay = max(relativeDelay);
                colorId = round((relativeDelay-minDelay)/(maxDelay-minDelay)*255+1);
                colorId(isnan(colorId)) = 128;
                groupCol = colorAssign(colorId,:)*255;
            end
            
            for i = 1:numel(groupCFUs)
                id = groupCFUs(i);
                if(id<=nCFU1)
                    overlayLabel1(se.myResize(cfuInfo1{id,3}>0.1,1/sclXY)) = i;
                else
                    overlayLabel2(se.myResize(cfuInfo2{id-nCFU1,3}>0.1,1/sclXY)) = i;
                end
            end
            cols1 = groupCol(1:nCFU1,:);
            cols2 = groupCol(nCFU1+1:end,:);
        end
        
        if ~isempty(cols1)
            cols1 = rgb2hsv(cols1/255);
            cols1(:,3) = min(1,cols1(:,3)*fh.sldCol.Value);
            cols1 = hsv2rgb(cols1);
        end
        if ~isempty(cols2)
            cols2 = rgb2hsv(cols2/255);
            cols2(:,3) = min(1,cols2(:,3)*fh.sldCol.Value);
            cols2 = hsv2rgb(cols2);
        end

        %% show
        if opts.singleChannel
            fh.ims.im1.Data = dat1;
            fh.ims.im1.Colormap = max(min(gray(256)*fh.sldBk.Value,1),0);

            alphaMap = zeros(opts.sz(1:3),'single');
            alphaMap(fh.msk) = 1 - fh.sldIntensityTrans.Value;
            fh.ims.im1.AlphaData = se.myResize(alphaMap,1/sclXY);

            fh.ims.im1.OverlayData = overlayLabel1;
            fh.ims.im1.OverlayColormap = [0,0,0;cols1];
            fh.ims.im1.OverlayAlphamap = 1 - fh.sldOverlayTrans.Value;
        else
            ims = {fh.ims.im2a,fh.ims.im2b};
            alphaMap = zeros(opts.sz(1:3),'single');
            alphaMap(fh.msk) = 1 - fh.sldIntensityTrans.Value;
            overlayLabel = cell(1,2); overlayLabel{1} = overlayLabel1; overlayLabel{2} = overlayLabel2;
            cols = cell(1,2); cols{1} = cols1; cols{2} = cols2;
            for ii = 1:2
                ims{ii}.Data = dat{ii};
                ims{ii}.Colormap = max(min(gray(256)*fh.sldBk.Value,1),0);
                ims{ii}.AlphaData = se.myResize(alphaMap,1/sclXY);
                ims{ii}.OverlayData = overlayLabel{ii};
                ims{ii}.OverlayColormap = [0,0,0;cols{ii}];
                ims{ii}.OverlayAlphamap = 1 - fh.sldOverlayTrans.Value;
            end
        end
    end
end