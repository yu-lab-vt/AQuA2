function click(~,evtDat,fCFU,f,channelNum,op)
    
    fh = guidata(fCFU);    
    
    if(channelNum==1)
        cfuMap = fh.cfuMap1;
    else
        cfuMap = fh.cfuMap2;
    end
    [H,W] = size(cfuMap);

    xy = evtDat.IntersectionPoint;
    x = max(round(xy(1)),1);
    y = max(round(xy(2)),1);
    y0 = min(max(H-y+1,1),H);
    x0 = min(max(x,1),W);
    curEvt = cfuMap(y0,x0);
    if(curEvt>0)
        if strcmp(op,'pick')
            notInExist = true;
            for i = 1:size(fh.selectCFUs,1)
                if(fh.selectCFUs(i,1)==channelNum && fh.selectCFUs(i,2)==curEvt)
                    fh.selectCFUs(i,:) = [];
                    notInExist = false;
                    break;
                end
            end
            if(notInExist)
                if(size(fh.selectCFUs,1)==2)
                    fh.selectCFUs(1,:) = [];
                end
                fh.selectCFUs = [fh.selectCFUs;channelNum,curEvt];
            end
            guidata(fCFU,fh);
            ui.updtCFUcurve([],[],fCFU,f);
        else
            cfuInfo1 = getappdata(fCFU,'cfuInfo1');
            nCFU1 = size(cfuInfo1,1);
            if channelNum==2
                curEvt = nCFU1 + curEvt;
            end

            if ismember(curEvt,fh.favCFUs)
                newLst = [];
                for i = 1:numel(fh.favCFUs)
                    if fh.favCFUs(i)~=curEvt
                        newLst = [newLst;fh.favCFUs(i)];
                    end
                end
                fh.favCFUs = newLst;
            else
                fh.favCFUs = [fh.favCFUs;curEvt];
            end
            guidata(fCFU,fh);
            cfu.updtCFUTable(fCFU);
            cfu.curveRefresh(fCFU,curEvt);
        end
        
        ui.updtCFUint([],[],fCFU,false);
        
    end
end