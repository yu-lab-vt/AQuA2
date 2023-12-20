function datx=imputeMov(datx)

T = size(datx,2);
for tt=2:T
    select = isnan(datx(:,tt));
    datx(select,tt) = datx(select,tt-1);
end
for tt=T-1:-1:1
    select = isnan(datx(:,tt));
    datx(select,tt) = datx(select,tt+1);
end

end