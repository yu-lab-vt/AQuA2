function pickCFU(~,~,fCFU,f,op)
    opts = getappdata(f,'opts');
    fh = guidata(fCFU);
    col = getappdata(f,'col');
    fh.pickButton.BackgroundColor = col;
    fh.viewButton.BackgroundColor = col;

    if strcmp(op,"pick")
        fh.viewButton.Value = 0;
    else
        fh.pickButton.Value = 0;
    end

    if opts.sz(3)==1
        if(~(fh.pickButton.Value || fh.viewButton.Value))
            if(opts.singleChannel)
                fh.ims.im1.ButtonDownFcn = [];
            else
                fh.ims.im2a.ButtonDownFcn = [];
                fh.ims.im2b.ButtonDownFcn = [];
            end
        else
            if(opts.singleChannel)
                fh.ims.im1.ButtonDownFcn = {@cfu.click,fCFU,f,1,op};
            else
                fh.ims.im2a.ButtonDownFcn = {@cfu.click,fCFU,f,1,op};
                fh.ims.im2b.ButtonDownFcn = {@cfu.click,fCFU,f,2,op};
            end
        end
    else
        if(fh.pickButton.Value || fh.viewButton.Value)
            fh.pSelect.Visible = 'on';
        else
            fh.pSelect.Visible = 'off';
        end
    end
    if fh.pickButton.Value
        fh.pickButton.BackgroundColor = [0.8,0.8,0.8];
    end
    if fh.viewButton.Value
        fh.viewButton.BackgroundColor = [0.8,0.8,0.8];
    end
    guidata(fCFU,fh);
end