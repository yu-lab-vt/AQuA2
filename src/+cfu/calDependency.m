function [pvalue,ds,distribution] = calDependency(sequence1, sequence2, possibleDists)
% condition is the first variable, occurrence is the second.

    if(~exist('possibleDists','var'))
       possibleDists = 0:10; 
    end
    sequence1 = reshape(sequence1,[1,numel(sequence1)]);
    sequence2 = reshape(sequence2,[1,numel(sequence2)]);
    [pvalue,ds,distribution] = getPvalue(sequence1,sequence2,possibleDists);
end
function [pvalue,d,distribution] = getPvalue(sequence1,sequence2,possibleDists)
    T = numel(sequence2);
    % sequence 2 depend on sequence 1:
    lambda = sum(sequence2)/T;
    pvalues = ones(numel(possibleDists),1);
    distribution = cell(numel(possibleDists),1);
    for k = 1:numel(possibleDists)
        % dilate
        dist = possibleDists(k);
        L = 2*dist+1;
        window = imdilate(sequence1,ones(1,L));
        cc = bwconncomp(window>0);
        cc = cc.PixelIdxList;
        cnt = 0;
        windows = cell(sum(sequence1),1);
        %% split window
        for i = 1:numel(cc)
            TW = cc{i};
            t00  = min(TW)-1;
            tstart = t00+1;
            pos = find(sequence1(TW)>0);
            for j = 1:numel(pos)-1
                mid = t00 + round((pos(j)+pos(j+1))/2)-1;
                cnt = cnt + 1;
                property = [];
                property.TW = tstart:mid;
                property.tCenter = t00+pos(j);
                windows{cnt} = property;
                tstart = mid+1;
            end
            cnt = cnt + 1;
            property = [];
            property.TW = tstart:max(TW);
            property.tCenter = t00+pos(end);
            windows{cnt} = property;
        end
        
        %% count
        count = 0;
        delays = nan(1,numel(windows));
        winSz = zeros(1,numel(windows));
        for i = 1:numel(windows)
           TW = windows{i}.TW;
           pos = find(sequence2(TW)>0) + min(TW) - 1;
           winSz(i) = numel(TW);
           if(~isempty(pos))
               count = count + 1;
               dis = pos - windows{i}.tCenter;
               [~,id] = min(abs(dis));
               delays(i) = dis(id);
           end
        end
        p = 1-exp(-lambda*winSz);
        pvalues(k) = cfu.myBinomialCDF(p,count);
        delays = delays(~isnan(delays));
        [count,delay] = groupcounts(delays');
        distribution{k} = [delay,count];
    end
    [pvalue,id] = min(pvalues);
    d = possibleDists(id);
    distribution = distribution{id};
end