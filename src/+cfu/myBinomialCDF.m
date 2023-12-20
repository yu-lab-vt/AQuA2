function estiP = myBinomialCDF(p,m)  
    if(m==0)
        estiP = 1;
    elseif(m==numel(p))
        estiP = exp(sum(log(p)));
    elseif (abs(m-sum(p))<1e-3)
        K_3d = sum(p-2*p.^2 + 2*p.^3);
        K_2d = sum((1-p).*p);
        estiP = 0.5 - 1/sqrt(2*pi)*(K_3d/6/K_2d^(3/2) - 1/2/sqrt(K_2d));
    else
        t_hat = cfu.solveK1d(p,m);
        K_2d = sum(p.*(1-p)*exp(t_hat)./(p*exp(t_hat)+1-p).^2);
        K_function = sum(log(p*exp(t_hat)+1-p));
        w_hat = sign(t_hat) * sqrt(2*(t_hat*m - K_function));
        u_hat = (1-exp(-t_hat)) * sqrt(K_2d);
        estiP = normcdf(w_hat,'upper') - normpdf(w_hat)*(1/w_hat-1/u_hat); 
    end
end