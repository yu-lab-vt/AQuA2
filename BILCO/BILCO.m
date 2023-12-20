function [minCut,maxFlow] = BILCO(ref,tst,Gij,smo,initialCut,winSize,metric)
    ref = double(ref);
    tst = double(tst);
    N = size(tst,1);
    T = size(ref,2);
    if(size(ref,1) ~= N)
        ref = repmat(ref,N,1);
    end
    graphRelation = [Gij,ones(size(Gij,1),1)*smo];
    
    if(~exist('metric','var') || isempty(metric))
        metric = 'squared';
    end
    if(~exist('initialCut','var') || isempty(initialCut))
        initialCut = ones(N,T-1);
    end
    
    if(~exist('winSize','var') || isempty(winSize))
        winSize = 10000;
    end
    [minCut,maxFlow] = BILCOMex(ref,tst,graphRelation,initialCut,winSize,metric);
%     disp(maxFlow)
end

