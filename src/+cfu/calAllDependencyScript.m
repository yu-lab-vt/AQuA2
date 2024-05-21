function relation = calAllDependencyScript(cfuInfo1, cfuInfo2, cfuOpts)
    
    cfuInfo = cell(size(cfuInfo1,1)+size(cfuInfo2,1),1);
    for k = 1:size(cfuInfo1,1)
        cfuInfo{k,1} = cfuInfo1{k,4};
    end
    for k = 1:size(cfuInfo2,1)
        cfuInfo{k+size(cfuInfo1,1),1} = cfuInfo2{k,4};
    end
    tic;
    nCFU = size(cfuInfo,1);
    maxDist = cfuOpts.cfuAnalysis.maxDist;        % unfixed time window, pick the most significant one
    shift = abs(cfuOpts.cfuAnalysis.shift);
    relation = cell(nCFU*nCFU,1);
    cnt = 0;
    parfor k = 1:nCFU*nCFU
        i = floor((k-1)/nCFU)+1;
        j = k-(i-1)*nCFU;
        if(j<=i)
            relation{k} = [];
        else
            seq1 = cfuInfo{i,1};
            seq2 = cfuInfo{j,1};
            [pvalue1,ds1,distribution1] = cfu.calDependency(seq1, seq2, shift, 0:maxDist); % condition is the first variable, occurrence is the second.
            [pvalue2,ds2,distribution2] = cfu.calDependency(seq2, seq1, shift, 0:maxDist); % condition is the first variable, occurrence is the second.
            delay = nan;
            if(pvalue1<pvalue2)
                pvalue = pvalue1;
                if(~isempty(distribution1))
                    delay = distribution1(:,1)'*distribution1(:,2)/sum(distribution1(:,2));
                end
            else
                pvalue = pvalue2;
                if(~isempty(distribution2))
                    delay = -distribution2(:,1)'*distribution2(:,2)/sum(distribution2(:,2));
                end
            end
            relation{k} = [i,j,pvalue,delay];
        end
    end

    thr = 1e-1;
    valid = false(nCFU*nCFU,1);
    parfor k = 1:nCFU*nCFU
        if(~isempty(relation{k})&& relation{k}(3)<thr) % rough filter
            valid(k) = true;
        end
    end
    relation = relation(valid);
    toc;
    
    relation = cell2mat(relation);
end