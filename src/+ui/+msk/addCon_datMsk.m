function [im1,pMov1] = addCon_datMsk(f,pDatMsk)
% masks image view ***********

% top level panels
bDat = uigridlayout(pDatMsk,'ColumnWidth',{'1x'},'RowHeight',{'1x'},'Padding',[0,10,0,10],'RowSpacing',10,'Tag','mskGrid');
pMov1 = uiaxes('Parent',bDat,'ActivePositionProperty','Position','Tag','imgMsk');
pMov1.XTick = [];
pMov1.YTick = [];
d0 = ones(100,100);
pMov1.XLim = [1 100];
pMov1.YLim = [1 100];
im1 = image(pMov1,'CData',flipud(d0));
im1.CDataMapping = 'scaled';
pMov1.DataAspectRatio = [1 1 1];

end

