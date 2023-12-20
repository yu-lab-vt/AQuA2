function saveWaves(~,~,f)

    opts = getappdata(f,'opts');
    selpath = uigetdir(opts.filePath1,'Choose output folder');
    if selpath==0
        return;
    end
    path0 = [selpath,filesep,opts.fileName1];
    
    if ~exist(path0,'file') && ~isempty(path0)
        mkdir(path0);    
    end
    
    path1 = [path0,filesep,'waves_whole_video'];
    path2 = [path0,filesep,'waves_event_duration'];
    if ~exist(path1,'file') && ~isempty(path1)
        mkdir(path1);    
    end
    if ~exist(path2,'file') && ~isempty(path2)
        mkdir(path2);    
    end
    
    fh = guidata(f);
    tb = fh.evtTable;
    dat = tb.Data;
    favLst = [];
    for ii=1:size(dat,1)
        if dat{ii,1}==1 && dat{ii,2}==1
            favLst = union(dat{ii,3},favLst);
        end
    end
    dffMat = getappdata(f,'dffMat1');
    fts = getappdata(f,'fts1');
    
    for i = 1:numel(favLst)
        evtID = favLst(i);
        curve = dffMat(evtID,:,1)';
        t0 = fts.curve.tBegin(evtID);
        t1 = fts.curve.tEnd(evtID);  
        
        Frame = [1:numel(curve)]';
        dff = curve;
        T = table(Frame,dff);
        writetable(T,[path1,filesep,'CH1_Evt',num2str(evtID),'.csv']);
        
        Frame = [t0:t1]';
        dff = curve(t0:t1);
        T = table(Frame,dff);
        writetable(T,[path2,filesep,'CH1_Evt',num2str(evtID),'.csv']);
    end  


    favLst = [];
    for ii=1:size(dat,1)
        if dat{ii,1}==1 && dat{ii,2}==2
            favLst = union(dat{ii,3},favLst);
        end
    end
    dffMat = getappdata(f,'dffMat2');
    fts = getappdata(f,'fts2');
    
    for i = 1:numel(favLst)
        evtID = favLst(i);
        curve = dffMat(evtID,:,1)';
        t0 = fts.curve.tBegin(evtID);
        t1 = fts.curve.tEnd(evtID);  
        
        Frame = [1:numel(curve)]';
        dff = curve;
        T = table(Frame,dff);
        writetable(T,[path1,filesep,'CH2_Evt',num2str(evtID),'.csv']);
        
        Frame = [t0:t1]';
        dff = curve(t0:t1);
        T = table(Frame,dff);
        writetable(T,[path2,filesep,'CH2_Evt',num2str(evtID),'.csv']);
    end  
end