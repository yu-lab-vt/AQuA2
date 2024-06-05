function outputCurves(dffAlignedMat1, ftsLst1, dffAlignedMat2, ftsLst2, opts, fpath, fname)
    nEvt = size(dffAlignedMat1,1);
    rowName = cell(nEvt,1);
    risetime10 = zeros(nEvt,1);
    for k = 1:nEvt
       risetime10(k) = ftsLst1.curve.dff1Begin(k);
    end
    mat = [nan(nEvt,1),risetime10,dffAlignedMat1];
    mat = [nan(1,113);mat];
    mat = (num2cell(mat));
    for k = 1:nEvt
        mat{k+1,1} = ['Event ',num2str(k)];
    end
    mat{1,1} = 'Event ID';
    mat{1,2} = '10% Rise time';
    for k = 1:111
        if k>11
            mat{1,k+2} = ['df/f0 at +',num2str(k-11)];
        else
            mat{1,k+2} = ['df/f0 at ',num2str(k-11)];
        end
    end
    mat = table(mat);
    writetable(mat,[fpath,filesep,fname,'_Ch1_curves.xlsx'],'WriteVariableNames',0,'WriteRowNames',0);
    if(~opts.singleChannel)
        nEvt = size(dffAlignedMat2,1);
        risetime10 = zeros(nEvt,1);
        for k = 1:nEvt
           risetime10(k) = ftsLst2.curve.dff1Begin(k);
        end
        mat = [nan(nEvt,1),risetime10,dffAlignedMat2];
        mat = [nan(1,113);mat];
        mat = (num2cell(mat));
        for k = 1:nEvt
            mat{k+1,1} = ['Event ',num2str(k)];
        end
        mat{1,1} = 'Event ID';
        mat{1,2} = '10% Rise time';
        for k = 1:110
            if k>11
                mat{1,k+2} = ['df/f0 at +',num2str(k-11)];
            else
                mat{1,k+2} = ['df/f0 at ',num2str(k-11)];
            end
        end
        mat = table(mat);
        writetable(mat,[fpath,filesep,fname,'_Ch2_curves.xlsx'],'WriteVariableNames',0,'WriteRowNames',0);
    end
end