function [stdMapOrg,stdMapSmo,tempVarOrg,correctPars] = noise_estimation_function(F0Pro,datOrg,datSmo,smo,evtSpatialMask,correctNoise)
% --- Piecewise linear function to model variance vs. F0 ---
% 3-segment inclined segments + 2-segment horizontal segments
% 02/02/2023, Xuelong

if ~exist('correctNoise','var')
    correctNoise = true;
end

%% variance map
% calculate the variance of raw data.
% tempMap => would be used to calculate 
tempMap = mean((datOrg(:,:,:,1:end-1) - datOrg(:,:,:,2:end)).^2,4,'omitnan');
% tempMap = median((datOrg(:,:,:,1:end-1) - datOrg(:,:,:,2:end)).^2,4,'omitnan')/0.9099*2;
tempVarOrg = tempMap/2;
if correctNoise         % just for test
    % consider 0 values are trunted, remove that part. Using truncated
    % Gaussian model to fit.
    % paramter to estimate noise from difference. The parameters are derived
    % from analytical formulat%ion
    countInValid = sum(datOrg==0,4);
    totalSamples = sum(~isnan(datOrg),4);
    ratio = countInValid./totalSamples;                    
    correctPars = pre.truncated_kept_var(ratio);
    % correct raw data's variance, if some are truncated
    varMapOrg = tempMap./correctPars;
else
    varMapOrg = tempVarOrg;
end

varMapOrg(~evtSpatialMask) = nan;
stdMapOrg = sqrt(pre.fit_F0_var(F0Pro,varMapOrg));

if smo == 0
    stdMapSmo = stdMapOrg;
    varMapSmo = varMapOrg;
    return
end

% Gaussian filter
dist = ceil(2*smo);
filter0 = zeros(dist*2+1,dist*2+1,dist*2+1);
filter0(dist+1,dist+1,dist+1) = 1;
filter0 = imgaussfilt(filter0,smo);
filter = filter0.^2;

% estimated variance from smoothed data
varMapSmo = mean((datSmo(:,:,:,1:end-1) - datSmo(:,:,:,2:end)).^2,4,'omitnan')/2;
% varMapSmo = median((datSmo(:,:,:,1:end-1) - datSmo(:,:,:,2:end)).^2,4,'omitnan')/0.9099;

% correct the variance according to truncated model
% Modified here at 10/19/2023, imfilter(varMapOrg,filter) => imfilter(tempVarOrg,filter)
if correctNoise
    varMapSmo = varMapSmo .* imfilter(tempMap./correctPars,filter)./imfilter(tempVarOrg,filter);
end
varMapSmo(~evtSpatialMask) = nan;

% correct the variance in the boundary (caused by smoothing operation)
correctMap2 = burst.correctBoundaryStd(smo,size(datOrg));

stdMapSmo = sqrt(pre.fit_F0_var(F0Pro,varMapSmo,correctMap2<1+1e-5));
stdMapSmo = stdMapSmo.*correctMap2;

end