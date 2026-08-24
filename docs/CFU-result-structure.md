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
| `cfuInfo1` | Cell array containing one row per channel 1 CFU. |
| `cfuInfo2` | Cell array containing one row per channel 2 CFU. Empty for single-channel data. |
| `cfuRelation` | Pairwise CFU dependency results. |
| `cfuGroupInfo` | CFU grouping results derived from `cfuRelation`. |
| `cfuOpts` | CFU detection, dependency-analysis, and grouping parameters. |
| `datPro` | Normalized average-intensity background image used by the CFU result viewer; it is not the full time-series movie. |
| `favCFUList` | Global indices of Favourite CFUs. Available in GUI-generated result files. |
| `spatialBoundary` | Saved spatial classification boundary. Available only when a boundary was drawn. |
| `manualCFUShapes` | Ellipse parameters for manually drawn CFUs. Available in newer GUI-generated result files. |

Older files or batch-generated files can contain fewer variables. Use `isfield(result, 'variableName')` before accessing optional variables.

## `cfuInfo1` and `cfuInfo2`

`cfuInfo1` and `cfuInfo2` are `nCFU × nColumn` cell arrays. Each row describes one CFU in the corresponding channel. `cfuInfo{i,1}` is the local CFU index within that channel.

For a combined channel 1/channel 2 analysis, channel 2 global CFU indices are offset by the number of channel 1 CFUs:

```matlab
globalIndexCh2 = size(cfuInfo1, 1) + localIndexCh2;
```

The number of columns can differ by AQuA2 version, channel, and enabled features. Check `size(cfuInfo, 2)` before reading optional columns.

| Column | Field | Type / Size | Description |
| --- | --- | --- | --- |
| 1 | CFU ID | scalar | Local CFU index in the current channel. |
| 2 | Event list | numeric vector | Event indices belonging to the CFU. Indices refer to the corresponding channel event list. A manual CFU stores events that overlap its ellipse. |
| 3 | Spatial map | `H × W × L` numeric array, or an equal-length vector | Spatial weight map. The usual CFU footprint is `map > 0.1`. Automatically detected CFUs can have weighted maps; manual ellipse CFUs use a binary map. |
| 4 | Occurrence sequence | logical `1 × T` | Estimated rising-frame sequence of member events. This sequence is used for dependency analysis. |
| 5 | Mean curve | numeric `1 × T` | Mean fluorescence curve within the CFU footprint. |
| 6 | Mean dF/F | numeric `1 × T` | Mean dF/F curve calculated from column 5. |
| 7 | Time window | logical `1 × T` | Frames in which the CFU's own events occur inside its footprint. |
| 8 | Non-time window | logical `1 × T` | Frames occupied by other CFUs in the same footprint but outside this CFU's time window. |
| 9 | Frequency statistics | scalar struct | Frequency summary with fields `count`, `mainFreq`, `method`, `peakFreq80`, and `dt`. |
| 10 | Gray-event list | numeric vector or empty | GUI channel 1 extension: filtered overlapping events from other CFUs. This column can be absent. It is normally empty for manual CFUs because their overlapping events are already stored in column 2. |
| 11 | Spatial class | numeric scalar or empty | Class label assigned by a saved spatial boundary. This column can be absent when no boundary was used. |
| 12 | Manual-CFU flag | logical scalar or empty | `true` identifies a manually drawn or adjusted ellipse CFU. Automatically detected CFUs are normally empty or `false`. |

### Frequency Statistics in Column 9

```matlab
stats = result.cfuInfo1{cfuId, 9};

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

Each element of `manualCFUShapes` contains `Version`, `Channel`, `Index`, `Center`, `SemiAxes`, and `RotationAngle`. These display parameters correspond to the manual-CFU flag in column 12.

## Example: Read One CFU

```matlab
result = load('example_res_cfu.mat');
info = result.cfuInfo1;
cfuId = 1;

eventIds = info{cfuId, 2};
footprint = info{cfuId, 3} > 0.1;
meanCurve = info{cfuId, 5};
meanDff = info{cfuId, 6};
timeWindow = info{cfuId, 7};

isManual = size(info, 2) >= 12 && isequal(info{cfuId, 12}, true);
hasSpatialClass = size(info, 2) >= 11 && ~isempty(info{cfuId, 11});
```
