# CFU Result File Structure

This document describes the CFU result file saved as `*_res_cfu.mat`. It is intended for users who want to load CFU features into MATLAB for custom analysis.

The file stores the listed variables at the top level.

```matlab
result = load('example_res_cfu.mat');
```

Spatial data follow `opts.sz = [H, W, L, T]`, where `H`, `W`, `L`, and `T` are the image height, width, number of z-slices, and number of frames. All event and CFU indices are MATLAB **1-based** indices.

## Top-Level Variables

| Variable | Description |
| --- | --- |
| `cfuInfo1` | Structure array containing one named record per channel 1 CFU. |
| `cfuInfo2` | Structure array containing one named record per channel 2 CFU. Empty for single-channel data. |
| `cfuRelation` | Pairwise CFU dependency results. |
| `cfuGroupInfo` | CFU grouping results derived from `cfuRelation`. |
| `cfuOpts` | CFU detection, dependency-analysis, and grouping parameters. |
| `datPro` | Normalized average-intensity background image used by the CFU result viewer; it is not the full time-series movie. |
| `favCFUList` | Global indices of Favourite CFUs. Available in GUI-generated result files. |
| `spatialBoundary` | Saved spatial classification boundary. Available only when a boundary was drawn. |
| `manualCFUShapes` | Ellipse parameters for manually drawn CFUs. Available in newer GUI-generated result files. |

Older files or batch-generated files can contain fewer variables. Use `isfield(result, 'variableName')` before accessing optional variables.

## `cfuInfo1` and `cfuInfo2`

`cfuInfo1` and `cfuInfo2` are `nCFU × 1` structure arrays. Each element describes one CFU in the corresponding channel. `cfuInfo(i).id` is the local CFU index within that channel.

For a combined channel 1/channel 2 analysis, channel 2 global CFU indices are offset by the number of channel 1 CFUs:

```matlab
globalIndexCh2 = size(cfuInfo1, 1) + localIndexCh2;
```

Current results always contain the fields below. When an older file is loaded in AQuA2, its legacy cell array is automatically converted to this structure format; unavailable historical values become empty fields.

| Field | Type / Size | Description |
| --- | --- | --- |
| `id` | scalar | Local CFU index in the current channel. |
| `eventIds` | numeric vector | Event indices belonging to the CFU. Indices refer to the corresponding channel event list. |
| `weightMap` | `H × W × L` numeric array, or an equal-length vector | Spatial weight map. The usual CFU footprint is `weightMap > 0.1`. |
| `occurrence` | logical `1 × T` | Estimated rising-frame sequence used for dependency analysis. |
| `meanCurve` | numeric `1 × T` | Mean fluorescence curve within the CFU footprint. |
| `meanDff` | numeric `1 × T` | Mean dF/F curve calculated from `meanCurve`. |
| `timeWindow` | logical `1 × T` | Frames in which the CFU's own events occur inside its footprint. |
| `nonTimeWindow` | logical `1 × T` | Frames occupied by other CFUs in the same footprint but outside this CFU's time window. |
| `frequencyStats` | scalar struct | Frequency summary with fields `count`, `mainFreq`, `method`, `peakFreq80`, and `dt`. |
| `grayEventIds` | numeric vector or empty | Filtered overlapping events from other CFUs. |
| `spatialClass` | numeric scalar or empty | Class label assigned by a saved spatial boundary. |
| `isManual` | logical scalar or empty | `true` identifies a manually drawn or adjusted ellipse CFU. |
| `parentId` | numeric scalar or empty | Original hierarchy cluster ID. |
| `memberships` | cell or struct | Shared-event local masks and scores. |

### Frequency Statistics

```matlab
stats = result.cfuInfo1(cfuId).frequencyStats;

stats.count        % Number of member events
stats.mainFreq     % Main frequency in Hz
stats.method       % 'Mean', 'Med', or 'N/A'
stats.peakFreq80   % 80th percentile of interval frequencies; NaN when unavailable
stats.dt           % Positive intervals between event peaks, in seconds
```

## `cfuRelation`

`cfuRelation` is an `nRelation × 4` numeric matrix. Each row is:

```matlab
[cfuIndex1, cfuIndex2, pValue, relativeDelay]
```

`cfuIndex1` and `cfuIndex2` are global CFU indices. `pValue` is the more significant p-value from the two dependency directions. `relativeDelay` is the associated relative delay in frames; its sign retains direction information used by the grouping procedure.

After manual CFU creation, adjustment, or deletion, recalculate `cfuRelation` and `cfuGroupInfo` before using them.

## `cfuGroupInfo`

`cfuGroupInfo` is an `nGroup × 4` cell array.

| Column | Description |
| --- | --- |
| 1 | Group index. |
| 2 | Global CFU indices in the group. |
| 3 | Relative delays aligned with column 2. |
| 4 | Connection p-values aligned with column 2. |

## Other CFU Variables

`cfuOpts` usually has the substructures `cfuDetect`, `cfuAnalysis`, and `cfuGroup`.

`favCFUList` uses global indices: channel 1 uses `1:nCFU1`, and channel 2 starts at `nCFU1 + 1`.

`spatialBoundary` contains `XData`, `YData`, `ClassA`, `ClassB`, `ImageSize`, and `ClassificationColumn`.

Each element of `manualCFUShapes` contains `Version`, `Channel`, `Index`, `Center`, `SemiAxes`, and `RotationAngle`. These display parameters correspond to the `isManual` field.

## Example: Read One CFU

```matlab
result = load('example_res_cfu.mat');
info = result.cfuInfo1;
cfuId = 1;

eventIds = info(cfuId).eventIds;
footprint = info(cfuId).weightMap > 0.1;
meanCurve = info(cfuId).meanCurve;
meanDff = info(cfuId).meanDff;
timeWindow = info(cfuId).timeWindow;

isManual = isequal(info(cfuId).isManual, true);
hasSpatialClass = ~isempty(info(cfuId).spatialClass);
```
