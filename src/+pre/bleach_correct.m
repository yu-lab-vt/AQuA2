function [datCorrect] = bleach_correct(dataIn)
    % 03/22/2023 Xuelong
    % global bleach correction
    disp('Bleach Correct ...')
    [H,W,L,T] = size(dataIn);
    
    % get the intensity projection
    datIn = reshape(dataIn,[],T);   
    trend = double(mean(datIn,1));
    trend = trend/trend(1);
    minV = inf;
    for t = 1:length(trend) % remove signal influence, only allow decrease
        minV = min(minV,trend(t));
        trend(t) = min(minV,trend(t));
    end
    x = [1:T];
    % fit - Exponential
    myFitType = fittype(@(a,b,c,d,x) a*exp(-b*x.^d)+c);
    myFit = fit(x',trend',myFitType,'Lower',[0,0,0,0],'Upper',...
    [inf,inf,min(trend),1],'StartPoint', [max(trend)-min(trend),0,min(trend),1]);
    fitCurve = myFit(x);
    fitCurve = reshape(fitCurve,[1,T]);
    datIn = datIn./repmat(fitCurve,H*W*L,1);
    datCorrect = reshape(datIn,[H,W,L,T]);
end