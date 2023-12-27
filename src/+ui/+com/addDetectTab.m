function addDetectTab(f,pDeOut)
% ----------- Modified by Xuelong Mi, 11/09/2022 -----------
% addDetectTab adds event detection pipeline panels in tabs        
    % top
    bDeOut = uigridlayout(pDeOut,'Padding',[0,5,0,0],'ColumnWidth',{'1x'},'RowHeight',{20,260,20,20},'RowSpacing',5);
    uilabel(bDeOut,'Text','Detection pipeline','BackgroundColor',[0 0.3 0.6],'FontColor','white');
    deOutTab = uitabgroup(bDeOut,'Tag','deOutTab');
    deOutCon = uigridlayout(bDeOut,'Padding',[10,0,10,0],'ColumnWidth',{'1x','1x','1x'},'RowHeight',{'1x'},'ColumnSpacing',10);
    deOutRunAll = uigridlayout(bDeOut,'Padding',[10,0,10,0],'ColumnWidth',{'1x','1x','1x'},'RowHeight',{'1x'},'ColumnSpacing',10);

    % tabs
    pPre = uitab(deOutTab,'Title','Pre','Tag','pBc','ForegroundColor',[.8,.8,.8]);
    pAct = uitab(deOutTab,'Title','Act','Tag','pAct','ForegroundColor',[.8,.8,.8]);
    pSp = uitab(deOutTab,'Title','Temp','Tag','pSp','ForegroundColor',[.8,.8,.8]);
    pEvt = uitab(deOutTab,'Title','Spa','Tag','pEvt','ForegroundColor',[.8,.8,.8]);
    pGlo = uitab(deOutTab,'Title','Glo','Tag','pGlo','ForegroundColor',[.8,.8,.8]);
    pFea = uitab(deOutTab,'Title','Fea','Tag','pFea','ForegroundColor',[.8,.8,.8]);
%     deOutTab.TabTitles = {'Preprocess','Active region','Temporal','Spatial','Global','Feature'};
    deOutTab.SelectionChangedFcn = {@ui.detect.flow,f,'chg'};
    
    % controls
    uibutton(deOutCon,'push','Text','Back','Tag','deOutBack','ButtonPushedFcn',{@ui.detect.flow,f,'back'});
    uibutton(deOutCon,'push','Text','Run','Tag','deOutRun','ButtonPushedFcn',{@ui.detect.flow,f,'run'});
    uibutton(deOutCon,'push','Text','Next','Tag','deOutNext','ButtonPushedFcn',{@ui.detect.flow,f,'next'});
    uibutton(deOutRunAll,'push','Text','SaveOpts','Tag','deSaveOpt','ButtonPushedFcn',{@ui.detect.saveOpt,f},'BackgroundColor',[.3,.5,.8],'FontColor','1,1,1');
    uibutton(deOutRunAll,'push','Text','LoadOpts','Tag','deLoadOpt','ButtonPushedFcn',{@ui.detect.loadOpt,f},'BackgroundColor',[.3,.5,.8],'FontColor','1,1,1');
    uibutton(deOutRunAll,'push','Text','RunAllSteps','Tag','deOutRunAll','ButtonPushedFcn',{@ui.detect.flow2,f},'BackgroundColor',[.3,.5,.8],'FontColor','1,1,1');
    
    % Preprocessing
    bPre = uigridlayout(pPre,'Padding',[5,5,5,5],'ColumnWidth',{30,'1x'},'RowHeight',{20,20,20,20,20,20,20,20},'RowSpacing',5,'ColumnSpacing',5);
    p = uilabel(bPre,'Text','------------------- Registration -------------------','HorizontalAlignment','center');
    p.Layout.Column  = [1,2];
    p = uidropdown(bPre,'Tag','registrateCorrect','Items',{'Not registrate','Rigid registration by cross correlation based on channel 1','Rigid registration by cross correlation based on channel 2'});
    p.Layout.Column  = [1,2];
    p = uilabel(bPre,'Text','-------------- Photobleach correction --------------');
    p.Layout.Column  = [1,2];
    p = uidropdown(bPre,'Tag','bleachCorrect','Items',{'Not correct bleach','Remove bleach globally','Remove bleach by intensity'});
    p.Layout.Column  = [1,2];
    p = uilabel(bPre,'Text','------ Remove salt and pepper noise (if have) ------','HorizontalAlignment','center');
    p.Layout.Column  = [1,2];
    uieditfield(bPre,'Value','0','Tag','medSmo');
    uilabel(bPre,'Text','Median filter radius (For salt and pepper noise)');
    p = uilabel(bPre,'Text','------- Baseline modeling and noise modeling -------','HorizontalAlignment','center');
    p.Layout.Column  = [1,2];
    uieditfield(bPre,'Value','1','Tag','smoXY');
    uilabel(bPre,'Text','Gaussian filter radius');
    
    % event detection: active region detection
    bAct = uigridlayout(pAct,'Padding',[5,5,5,5],'ColumnWidth',{50,'1x'},'RowHeight',{20,20,15,20,20,20,20,'1x'},'RowSpacing',3,'ColumnSpacing',5);
    p = uilabel(bAct,'Text','-------------- Thresholding --------------','HorizontalAlignment','center');
    p.Layout.Column  = [1,2];
    uieditfield(bAct,'Value','3','Tag','thrArScl','ValueChangedFcn',{@ui.mov.thrAdjust,f,0});
    uilabel(bAct,'Text','Intensity threshold scaling factor','Tag','thrContent');
    p = uislider(bAct,'Tag','sldActThr','MajorTicks',[],'MinorTicks',[],'ValueChangedFcn',{@ui.mov.thrAdjust,f,1});
    p.Layout.Column  = [1,2];
    p = uilabel(bAct,'Text','----------------- Filter -----------------','HorizontalAlignment','center');
    p.Layout.Column  = [1,2];
    uieditfield(bAct,'Value','5','Tag','minDur'); uilabel(bAct,'Text','Minimum duration');
    uieditfield(bAct,'Value','8','Tag','minSize'); uilabel(bAct,'Text','Minimum size (pixels)');
    p = uicheckbox(bAct,'Text','Advanced filters','Value',0,'Tag','advFilter','ValueChangedFcn',{@ui.com.advFilters,f});
    p.Layout.Column  = [1,2];
    gAct3 = uigridlayout(bAct,'Padding',[20,0,0,0],'ColumnWidth',{50,'1x'},'RowHeight',{20,20},'RowSpacing',3,'ColumnSpacing',5,'Tag','gAct3');
    gAct3.Layout.Column  = [1,2];
    uieditfield(gAct3,'Value','inf','Tag','maxSize'); uilabel(gAct3,'Text','Maximum size (pixels)');
    uieditfield(gAct3,'Value','0','Tag','circularityThr');  uilabel(gAct3,'Text','Circurlarity threshold for active region');
%     uieditfield(gAct3,'Value','0','Tag','spaMergeDist'); uilabel(gAct3,'Text','Allowed distance in the same signal');
    gAct3.Visible = 'off';

    % event detection: temporal segmentation
    bPhase = uigridlayout(pSp,'Padding',[5,5,5,5],'ColumnWidth',{'1x'},'RowHeight',{20,170},'RowSpacing',5,'ColumnSpacing',5);
    uicheckbox(bPhase,'Text','Need temporal segmentation?','Value',1,'Tag','needTemp','ValueChangedFcn',{@ui.com.ableTemp,f});
    gPhase = uigridlayout(bPhase,'Tag','tempSetting','Padding',[0,0,0,0],'ColumnWidth',{50,'1x'},'RowHeight',{20,20,20,20,20,20,20},'RowSpacing',5,'ColumnSpacing',5);
    p = uilabel(gPhase,'Text','----------------------Seed Detection----------------------','HorizontalAlignment','center');
    p.Layout.Column  = [1,2];
    uieditfield(gPhase,'Value','0.01','Tag','seedSzRatio'); uilabel(gPhase,'Text','Seed size relative to active region');
    uieditfield(gPhase,'Value','3.5','Tag','sigThr'); uilabel(gPhase,'Text','Zscore of seed significance');
    p = uilabel(gPhase,'Text','----------- Merge regions with similar signals -----------','HorizontalAlignment','center');
    p.Layout.Column  = [1,2];
    uieditfield(gPhase,'Value','0.8','Tag','maxDelay'); uilabel(gPhase,'Text','Allowed maximum dissimilarity in merging');
    p = uicheckbox(gPhase,'Text','Peaks are temporally adjacent, need refine','Value',0,'Tag','needRefine');
    p.Layout.Column  = [1,2];
    p = uicheckbox(gPhase,'Text','Grow active regions according to signal pattern','Value',0,'Tag','needGrow');
    p.Layout.Column  = [1,2];
    
    % event detection: spatial segmentation
    bEvt = uigridlayout(pEvt,'Padding',[5,5,5,5],'ColumnWidth',{'1x'},'RowHeight',{20,105},'RowSpacing',5,'ColumnSpacing',5);
    uicheckbox(bEvt,'Text','Need spatial segmentation?','Value',1,'Tag','needSpa','ValueChangedFcn',{@ui.com.ableSpa,f});
    gEvt = uigridlayout(bEvt,'Tag','spaSetting','Padding',[0,0,0,0],'ColumnWidth',{50,'1x'},'RowHeight',{20,20,20,20},'RowSpacing',5,'ColumnSpacing',5);
    p = uilabel(gEvt,'Text','--------------Spatial segmentation setting--------------','HorizontalAlignment','center');
    p.Layout.Column  = [1,2];
    uieditfield(gEvt,'Value','0.01','Tag','sourceSzRatio');uilabel(gEvt,'Text','Source size relative to super event');
    uieditfield(gEvt,'Value','8','Tag','sourceSensitivity');uilabel(gEvt,'Text','Sensitivity to detect source (Level 1 to 10)');
    p = uicheckbox(gEvt,'Text','Need temporal extension?','Value',1,'Tag','whetherExtend');
    p.Layout.Column  = [1,2];
    
    % Global signal
    bGlo = uigridlayout(pGlo,'Padding',[5,5,5,5],'ColumnWidth',{'1x'},'RowHeight',{20,20},'RowSpacing',5,'ColumnSpacing',5);
    uicheckbox(bGlo,'Text','Whether detect global signal?','Value',0,'Tag','detectGlo','ValueChangedFcn',{@ui.com.ableGlo,f});
    gGlo = uigridlayout(bGlo,'Tag','gloSetting','Padding',[0,0,0,0],'ColumnWidth',{50,'1x'},'RowHeight',{'1x'},'RowSpacing',5,'ColumnSpacing',5);
    uieditfield(gGlo,'Value','20','Tag','gloDur');uilabel(gGlo,'Text','Global signal duration');
    gGlo.Visible = 'off';

    % Extract feature
    bFea = uigridlayout(pFea,'Padding',[5,5,5,5],'ColumnWidth',{'1x'},'RowHeight',{20,66,20,'1x'},'RowSpacing',5,'ColumnSpacing',5);
    uicheckbox(bFea,'Text','Ignore delay Tau','Value',1,'Tag','ignoreTau');
    bProp = uigridlayout(bFea,'Padding',[0,0,0,0],'ColumnWidth',{10,'1x'},'RowHeight',{20,20,20},'RowSpacing',2,'ColumnSpacing',5);
    p = uicheckbox(bProp,'Text','Propagation metric relative to starting point in','Value',0,'Tag','propMetric');
    p.Layout.Column = [1,2];
    p = uilabel(bProp,'Text','different directions (Propagation map is already');
    p.Layout.Column = 2;
    p = uilabel(bProp,'Text','calculated)');
    p.Layout.Column = 2;
    uicheckbox(bFea,'Text','Network features','Value',0,'Tag','networkFeatures');
end

