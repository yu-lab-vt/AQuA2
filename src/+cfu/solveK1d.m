function mid = solveK1d(p,m)
    if(m==numel(p))
        mid = inf;
        return;
    end
    s = -1000;
    t = 1000;
    mid = (s+t)/2;
    mV = getValue(p,m,mid);
    while(abs(mV)>1e-10)
        if(mV>0)
            t = mid;
        else
            s = mid;
        end
        mid = (s+t)/2;
        mV = getValue(p,m,mid);
    end
    result = mid;

end

function value = getValue(p,m,t)
%     value = n*(1-(1-p)/(p*exp(t)+1-p))-m;
    value = sum((1-(1-p)./(p*exp(t)+1-p)))-m;
end