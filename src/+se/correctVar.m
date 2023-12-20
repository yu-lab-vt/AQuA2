function [stdBg] = correctVar(bg,fg)
    M = numel(fg);
    N = numel(bg);
    n = M+N;
    all = [bg;fg];
    labels = [true(N,1); false(M,1)];    
    [~, od] = sort(all); % ascending
    labels = labels(od);

    global mus
    global covMatrixs
    if isempty(mus) || isempty(covMatrixs)
        load('Order_mus_sigmas.mat');
    end
    mu = mus{n};
    vars = diag(covMatrixs{n});
    muBg = 1/N*sum(mu(labels));
    varBg = 1/N*sum(vars(labels) + mu(labels).^2) - muBg^2;
    stdBg = sqrt(varBg);
end