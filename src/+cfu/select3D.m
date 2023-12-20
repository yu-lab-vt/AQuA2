function select3D(~,~,fCFU,f)

fh = guidata(fCFU);    
cfuMap = fh.cfuMapDS1;
x = round(fh.xPos.Value);
y = round(fh.yPos.Value);
z = round(fh.zPos.Value);
channelNum = 1;

curEvt = cfuMap(y,x,z);
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
    
    guidata(fCFU,fh);
    ui.updtCFUint([],[],fCFU,false);
    
end


end


