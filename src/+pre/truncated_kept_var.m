function pars = truncated_kept_var(quantiles)
% The correction  parameter using average difference of adjacent pixels to  
% estimate variance for one-side truncated normal randoms. The elements 
% that are truncated are still used.
% Xuelong: 02/01/2023
%     a = norminv(quantiles);
%     phi_a = normpdf(a);
%     mu = a .* quantiles + phi_a;
%     Z = 1 - quantiles;
%     var_truncated = 1 + a.*phi_a ./ Z - (phi_a./Z).^2;
%     second_order = a.^2 .* quantiles + Z.*(var_truncated + (phi_a./Z).^2);
%     pars = (second_order - mu.^2)*2;
%     pars(quantiles==0) = 2;

    a = norminv(quantiles);
    phi_a = normpdf(a);
    mu = a .* quantiles + phi_a;
    second_order = a.^2 .* quantiles + 1-quantiles + a.*phi_a;
    pars = (second_order - mu.^2)*2;
    pars(quantiles==0) = 2;
end