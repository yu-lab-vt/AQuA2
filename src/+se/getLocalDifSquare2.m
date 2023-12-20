function difSquare = getLocalDifSquare2(bg1,bg2,nanV,fg)
    % way 1
%     correctPar = se.correctVar([bg1;bg2;nanV],fg);
%     difSquare = [(bg1(2:end) - bg1(1:end-1)).^2;(bg2(2:end) - bg2(1:end-1)).^2;(nanV(2:end) - nanV(1:end-1)).^2];
%     difSquare = difSquare/correctPar^2;

    % way 2
    % E[(X-Y)^2] = E[X^2] + E[Y^2] - 2E[XY] = Var[X] + \mu_X^2 + Var[Y] + \mu_Y^2 - 2*(cov(X,Y)+\mu_x\mu_Y)
    all = [bg1;bg2;nanV;fg];
    n = numel(all);
    n1 = numel(bg1);
    n2 = numel(bg2);
    n3 = numel(nanV);
    [~,od] = sort(all);
    id = zeros(n,1);
    id(od) = 1:n;
    global mus
    global covMatrixs
    if isempty(mus) || isempty(covMatrixs)
        load('Order_mus_sigmas.mat');
    end
    mu = mus{n};
    covMatrix = covMatrixs{n};
    difSquare = [(bg1(2:end) - bg1(1:end-1)).^2;(bg2(2:end) - bg2(1:end-1)).^2;(nanV(2:end) - nanV(1:end-1)).^2];
    id1 = id([2:n1,n1+2:n1+n2,n1+n2+2:n1+n2+n3]);
    id2 = id([1:n1-1,n1+1:n1+n2-1,n1+n2+1:n1+n2+n3-1]);
    vars = diag(covMatrix);
    correctPars = vars(id1) + mu(id1).^2 + vars(id2) + mu(id2).^2 - 2*(mu(id1).*mu(id2) + covMatrix(sub2ind([n,n],id1,id2)));
    difSquare = difSquare./correctPars*2;
end