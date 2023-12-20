function [TW,tPeak] = getMajorityTem(curve,t00,t11,t0,t1)
% Modified by Xuelong, 02/21/2023
% get the major time window of curve
% t00 and t11 are the bounds
% t0,t1 are the seed time window

    %% Spatial majority
    s0 = 1; % already normalized
    [~,tPeak] = max(curve(t00:t11));
    tPeak = tPeak + t00 - 1;

    % start time
    [minV,tw0] = min(curve(t00:tPeak));
    tw0 = tw0 + t00 - 1;

    ts = tw0;
    
    for t = tw0:-1:t0
        if(curve(t)<minV)
            minV = curve(t);
            ts = t;
        else
            if(curve(t)-minV>=3*s0)
                break;
            end
        end
    end

    % end time
    [minV,tw1] = min(curve(tPeak:t11));
    tw1 = tw1 + tPeak - 1;

    te = tw1;
    for t = tw1:t1
        if(curve(t)<minV)
            minV = curve(t);
            te = t;
        else
            if(curve(t)-minV>=3*s0)
                break;
            end
        end
    end
       
%     %% let it symmetric
%     if(curve(ts)>curve(te))
%         while(curve(te)<curve(ts))
%             te = te-1;
%         end
%     else
%         while(curve(te)>curve(ts))
%             ts = ts + 1;
%         end
%     end
%     ts = min(ts,TW(1));
%     te = max(te,TW(end));

    TW = ts:te;
end