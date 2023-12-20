function res = avgDist(curve1,curve2,TW1,TW2)
% ----------- Modified by Xuelong Mi, 11/09/2022 -----------
    %% align same part
    % curve 1
    [~,tPeak1] = max(curve1);
    minVL1 = min(curve1(1:tPeak1));
    minVR1 = min(curve1(tPeak1:end));

    % curve 2
    [~,tPeak2] = max(curve2);
    minVL2 = min(curve2(1:tPeak2));
    minVR2 = min(curve2(tPeak2:end));
    
    % TW limitation: only check the common part that larger than 10%
    thrL = max([minVL1,minVL2,0.1]);
    thrR = max([minVR1,minVR2,0.1]);

    % curve 1
    t00 = find(curve1(1:tPeak1)<=thrL,1,'last') + 1;
    t11 = find(curve1(tPeak1:end)<=thrR,1) + tPeak1 - 2;
    if t00>t11 % in case error
        t00 = tPeak1; t11 = tPeak1; 
    end
    curve01 = curve1;   % copy for check 
    TW001 = TW1;
    curve1 = curve1(t00:t11);   TW1 = TW1(t00:t11);
    if(t11>t00)
        curve1 = curve1-min(thrL,thrR);
    end
    curve1 = curve1/max(curve1);
    
    % curve 2
    t00 = find(curve2(1:tPeak2)<=thrL,1,'last') + 1;
    t11 = find(curve2(tPeak2:end)<=thrR,1) + tPeak2 - 2;
    if t00>t11 
        t00 = tPeak2; t11 = tPeak2; 
    end
    curve2 = curve2(t00:t11);   TW2 = TW2(t00:t11);
    if(t11>t00)
        curve2 = curve2 - min(thrL,thrR);
    end
    curve2 = curve2/max(curve2);

    % other work
    ts1 = min(TW1);
    ts2 = min(TW2);
    te1 = max(TW1);
    te2 = max(TW2);
    
    addValueL = 0;
    if(ts1<ts2)
        curve2 = [addValueL*ones(1,ts2-ts1),curve2];
    else
        curve1 = [addValueL*ones(1,ts1-ts2),curve1];
    end
    
    addValueR = 0;
    if(te1<te2)
        curve1 = [curve1,addValueR*ones(1,te2-te1)];
    else
        curve2 = [curve2,addValueR*ones(1,te1-te2)];
    end
    curve1 = [0,curve1,0];
    curve2 = [0,curve2,0];
    [~,ix,iy] = dtw(curve1,curve2);
    
    select1 = curve1(ix)>0;
    select2 = curve2(iy)>0;
    res1 = sum(abs(iy(select1)-ix(select1)));
    res2 = sum(abs(iy(select2)-ix(select2)));
    % (summation dif/corresponding pair)/duration
    minDur = min(sum(curve1>0),sum(curve2>0)) + 2;    % add left 0 and right 0
    res = (res1+res2)/(sum(select1)+sum(select2))/minDur;
end