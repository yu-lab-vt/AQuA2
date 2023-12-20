function root = findRootLabel(labels,id)
    if (labels(id) ~= id)
        labels(id) = cfu.findRootLabel(labels, labels(id));
    end
    root = labels(id);
end