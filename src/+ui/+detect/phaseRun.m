function phaseRun(~,~,f)
% Xuelong Mi 02/09/2023

fprintf('Detecting ...\n')

fh = guidata(f);

opts = getappdata(f,'opts');
opts.needTemp = fh.needTemp.Value;
ff = waitbar(0,'Detecting Channel 1...');
if(fh.needTemp.Value)
    opts.step = 0.5;    % 0.5 sigma
    opts.sigThr = str2double(fh.sigThr.Value);
    opts.maxDelay = str2double(fh.maxDelay.Value);
    opts.seedSzRatio = str2double(fh.seedSzRatio.Value);
    opts.needRefine = fh.needRefine.Value;
    opts.needGrow = fh.needGrow.Value;
    

    dF1 = getappdata(f,'dF1');
    datOrg1 = getappdata(f,'datOrg1');
    arLst1 = getappdata(f,'arLst1');
%     ff = waitbar(0,'Detecting Channel1 ...');
    opts.tempVarOrg = opts.tempVarOrg1;
    opts.correctPars = opts.correctPars1;
    [seLst1,subEvtLst1,seLabel1,majorInfo1,opts,sdLst1,~,~] = se.seDetection(dF1,datOrg1,arLst1,opts,ff);
    % save data
    setappdata(f,'subEvtLst1',subEvtLst1);
    setappdata(f,'seLst1',seLst1);
    setappdata(f,'seLabel1',seLabel1);
    setappdata(f,'majorInfo1',majorInfo1);
    clear dF1;

    if(~opts.singleChannel)
        delete(ff);
        dF2 = getappdata(f,'dF2');
        datOrg2 = getappdata(f,'datOrg2');
        arLst2 = getappdata(f,'arLst2');
        ff = waitbar(0,'Detecting Channel2 ...');
        opts.tempVarOrg = opts.tempVarOrg2;
        opts.correctPars = opts.correctPars2;
        [seLst2,subEvtLst2,seLabel2,majorInfo2,opts,sdLst2,~,~] = se.seDetection(dF2,datOrg2,arLst2,opts,ff);
        clear dF2;
    else
        seLst2 = [];    
        sdLst2 = [];    
        subEvtLst2 = []; 
        seLabel2 = []; 
        majorInfo2 = [];
    end

    % save data
    setappdata(f,'subEvtLst2',subEvtLst2);
    setappdata(f,'seLst2',seLst2);
    setappdata(f,'seLabel2',seLabel2);
    setappdata(f,'majorInfo2',majorInfo2);
    setappdata(f,'opts',opts);

else
    opts = getappdata(f,'opts');
    arLst1 = getappdata(f,'arLst1'); 
    if(~opts.singleChannel)
        arLst2 = getappdata(f,'arLst2');
    else
        arLst2 = [];
    end
    

    sdLst1 = arLst1;
    sdLst2 = arLst2; 
    seLst1 = arLst1; 
    seLst2 = arLst2; 
    subEvtLst1 = arLst1; 
    subEvtLst2 = arLst2; 
    seLabel1 = 1:numel(seLst1);
    setappdata(f,'subEvtLst1',seLst1);
    setappdata(f,'seLst1',seLst1);
    setappdata(f,'seLabel1',seLabel1);
    dF1 = getappdata(f,'dF1');
    setappdata(f,'majorInfo1',se.getMajority_Ac(seLst1,seLst1,dF1,opts));
    clear dF1;

    seLabel2 = 1:numel(seLst2);
    setappdata(f,'subEvtLst2',seLst2);
    setappdata(f,'seLst2',seLst2);
    setappdata(f,'seLabel2',seLabel2);
    dF2 = getappdata(f,'dF2');
    setappdata(f,'majorInfo2',se.getMajority_Ac(seLst2,seLst2,dF2,opts));
    clear dF2;
end
waitbar(1,ff);

ui.detect.postRun([],[],f,sdLst1,sdLst2,[],[],'Step 3aa: seeds');
ui.detect.postRun([],[],f,subEvtLst1,subEvtLst2,[],[],'Step 3a: watershed results');
ui.detect.postRun([],[],f,seLst1,seLst2,[],[],'Step 3b: super events');

fh.nEvtName.Text = 'nSe';
if(~opts.singleChannel)
    fh.nEvt.Text = [num2str(numel(seLst1)),' | ',num2str(numel(seLst2))];
else
    fh.nEvt.Text = [num2str(numel(seLst1))];
end

fprintf('Done\n')
delete(ff);
end





