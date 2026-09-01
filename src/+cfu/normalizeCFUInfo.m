function info = normalizeCFUInfo(info)
%normalizeCFUInfo Convert legacy CFU cell arrays to named record structs.
%
% The current representation is an N-by-1 structure array.  This function
% also fills fields omitted by earlier result-file versions, so callers can
% safely use the complete named schema after loading.

    template = emptyRecord();
    fieldNames = fieldnames(template);

    if isempty(info)
        info = repmat(template, 0, 1);
        return;
    end

    if iscell(info)
        numberOfRecords = size(info, 1);
        converted = repmat(template, numberOfRecords, 1);
        numberOfColumns = size(info, 2);
        for recordIndex = 1:numberOfRecords
            for fieldIndex = 1:min(numberOfColumns, numel(fieldNames))
                converted(recordIndex).(fieldNames{fieldIndex}) = ...
                    info{recordIndex, fieldIndex};
            end
            if isempty(converted(recordIndex).id)
                converted(recordIndex).id = recordIndex;
            end
        end
        info = converted;
        return;
    end

    if ~isstruct(info)
        error('cfu:InvalidCFUInfo', ...
            'CFU information must be a structure array or a legacy cell array.');
    end

    info = info(:);
    for recordIndex = 1:numel(info)
        for fieldIndex = 1:numel(fieldNames)
            fieldName = fieldNames{fieldIndex};
            if ~isfield(info, fieldName)
                info(recordIndex).(fieldName) = template.(fieldName);
            end
        end
        if isempty(info(recordIndex).id)
            info(recordIndex).id = recordIndex;
        end
    end
    info = orderfields(info, template);
end

function record = emptyRecord()
% Column order deliberately matches legacy CFU cell arrays.
    record = struct( ...
        'id', [], ...
        'eventIds', [], ...
        'weightMap', [], ...
        'occurrence', [], ...
        'meanCurve', [], ...
        'meanDff', [], ...
        'timeWindow', [], ...
        'nonTimeWindow', [], ...
        'frequencyStats', [], ...
        'grayEventIds', [], ...
        'spatialClass', [], ...
        'isManual', [], ...
        'parentId', [], ...
        'memberships', []);
end
