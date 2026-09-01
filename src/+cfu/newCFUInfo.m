function info = newCFUInfo(numberOfRecords)
%newCFUInfo Create CFU information records using the current named schema.

    if nargin < 1
        numberOfRecords = 0;
    end
    validateattributes(numberOfRecords, {'numeric'}, {'scalar', 'integer', 'nonnegative'});

    template = cfu.normalizeCFUInfo(cell(1, 14));
    info = repmat(template, numberOfRecords, 1);
    for recordIndex = 1:numberOfRecords
        info(recordIndex).id = recordIndex;
    end
end
