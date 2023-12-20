function [datCorrect,pixCluster,fitCurves] = bleach_correct2(datIn,opts,ff)
    % 03/22/2023 Xuelong
    % concise code for bleach correction of different intensity groups
    [H,W,L,T] = size(datIn);
    myFitType = fittype(@(a,b,c,d,x) a*exp(-b*x.^d)+c);
    
    datIn = reshape(datIn,[],T);
    
    % get the mean intensity projection
    datMean = zeros(H*W*L,1);
    for t = 1:T
       datMean = datMean + datIn(:,t)/mean(datIn(:,t));
    end
    datMean = datMean-min(datMean(:));
    datMean = datMean/max(datMean(:));
    
    % clusterMap
    clusterMap = zeros(H,W,L);

    if exist('ff','var')
        waitbar(0.1,ff);
    end

    %% way 1: Top to bottom, select pixels of different intensity level, 
    %% then do bleach correction
    ub = 1.01;
    step = 0.01;
    lb = 1;
    pixLimit = 2000;
    fitCurves = cell(0);
    
    cnt = 1;
    while ub>0
        pix = [];
        while(numel(pix)<pixLimit)
            lb = lb - step;
            pix = find(datMean>=lb & datMean<ub);
            if(lb<0)
               break; 
            end
        end

        if exist('ff','var')
            waitbar(0.1 + 0.9*(1-ub),ff);
        end

        if(lb>=0)
            trend0 = double(mean(datIn(pix,:),1));
            trend0 = trend0/trend0(1);
            trend = trend0;
            minV = inf;
            for t = 1:length(trend)
                minV = min(minV,trend(t));
                trend(t) = min(minV,trend(t));
            end
            x = [1:T];
            % fit - Exponential
            myFit = fit(x',trend',myFitType,'Lower',[0,0,0,0],'Upper',...
            [inf,inf,min(trend),1],'StartPoint', [max(trend)-min(trend),0,min(trend),1]);
            fitCurve = reshape(myFit(x),[1,T]);
%             figure;plot(trend0);hold on;plot(fitCurve);
        end
        clusterMap(pix) = cnt;
        fitCurves{cnt} = fitCurve;
        cnt = cnt + 1;
        ub = lb;
    end
    
    pixCluster = label2idx(clusterMap);
    
    for i = 1:numel(pixCluster)
        fitCurve = fitCurves{i};
        pix = pixCluster{i};
        datIn(pix,:) = datIn(pix,:)./repmat(fitCurve,numel(pix),1);
    end
    datCorrect = reshape(datIn,[H,W,L,T]);
%     toc;
end