function [B,map] = myResize(varargin)
%IMRESIZE Resize image.
%   B = IMRESIZE(A, SCALE) returns an image that is SCALE times the
%   size of A, which is a grayscale, RGB, or binary image. If A has more
%   than two dimensions, only the first two dimensions are resized.
%  
%   B = IMRESIZE(A, [NUMROWS NUMCOLS]) resizes the image so that it has
%   the specified number of rows and columns.  Either NUMROWS or NUMCOLS
%   may be NaN, in which case IMRESIZE computes the number of rows or
%   columns automatically in order to preserve the image aspect ratio.
%  
%   [Y, NEWMAP] = IMRESIZE(X, MAP, SCALE) resizes an indexed image.
%  
%   [Y, NEWMAP] = IMRESIZE(X, MAP, [NUMROWS NUMCOLS]) resizes an indexed
%   image.
%  
%   To control the interpolation method used by IMRESIZE, add a METHOD
%   argument to any of the syntaxes above, like this:
%
%       IMRESIZE(A, SCALE, METHOD) 
%       IMRESIZE(A, [NUMROWS NUMCOLS], METHOD),
%       IMRESIZE(X, MAP, M, METHOD)
%       IMRESIZE(X, MAP, [NUMROWS NUMCOLS], METHOD)
%
%   METHOD can be a string naming a general interpolation method:
%  
%       'nearest'    - nearest-neighbor interpolation
% 
%       'bilinear'   - bilinear interpolation
% 
%       'bicubic'    - cubic interpolation; the default method
%
%   METHOD can also be a string naming an interpolation kernel:
%
%       'box'        - interpolation with a box-shaped kernel
%
%       'triangle'   - interpolation with a triangular kernel
%                         (equivalent to 'bilinear')
%
%       'cubic'      - interpolation with a cubic kernel 
%                         (equivalent to 'bicubic')
%  
%       'lanczos2'   - interpolation with a Lanczos-2 kernel
%  
%       'lanczos3'   - interpolation with a Lanczos-3 kernel
%
%   Finally, METHOD can be a two-element cell array of the form {f,w},
%   where f is the function handle for a custom interpolation kernel, and
%   w is the custom kernel's width.  f(x) must be zero outside the
%   interval -w/2 <= x < w/2.  Your function handle f may be called with a
%   scalar or a vector input.
%  
%   You can achieve additional control over IMRESIZE by using
%   parameter/value pairs following any of the syntaxes above.  For
%   example:
%
%       B = IMRESIZE(A, SCALE, PARAM1, VALUE1, PARAM2, VALUE2, ...)
%
%   Parameters include:
%  
%       'Antialiasing'  - true or false; specifies whether to perform 
%                         antialiasing when shrinking an image. The
%                         default value depends on the interpolation 
%                         method you choose.  For the 'nearest' method,
%                         the default is false; for all other methods,
%                         the default is true.
%
%       'Colormap'      - (only relevant for indexed images) 'original'
%                         or 'optimized'; if 'original', then the
%                         output newmap is the same as the input map.
%                         If it is 'optimized', then a new optimized
%                         colormap is created. The default value is
%                         'optimized'. 
%
%       'Dither'        - (only for indexed images) true or false;
%                         specifies whether to perform color
%                         dithering. The default value is true.
%  
%       'Method'        - As described above
%  
%       'OutputSize'    - A two-element vector, [MROWS NCOLS],
%                         specifying the output size.  One element may
%                         be NaN, in which case the other value is
%                         computed automatically to preserve the aspect
%                         ratio of the image. 
%  
%       'Scale'         - A scalar or two-element vector specifying the
%                         resize scale factors.  If it is a scalar, the
%                         same scale factor is applied to each
%                         dimension.  If it is a vector, it contains
%                         the scale factors for the row and column
%                         dimensions, respectively.
%
%   Examples
%   --------
%   Shrink by factor of two using the defaults of bicubic interpolation
%   and antialiasing.
%
%       I = imread('ngc6543a.jpg');
%       J = imresize(I, 0.5);
%       figure, imshow(I), figure, imshow(J)
%
%   Shrink by factor of two using nearest-neighbor interpolation.
%   (This is the fastest method, but it has the lowest quality.)
%
%       I = imread('ngc6543a.jpg');
%       J2 = imresize(I, 0.5, 'nearest');
%
%   Resize an indexed image.
%
%       [X, map] = imread('corn.tif');
%       [Y, newmap] = imresize(X, map, 0.5);
%       imshow(Y, newmap)
%
%   Resize an RGB image to have 64 rows.  The number of columns is
%   computed automatically.
%
%       RGB = imread('peppers.png');
%       RGB2 = imresize(RGB, [64 NaN]);
%  
%   Note
%   ----
%   For bicubic interpolation, the output image may have some values
%   slightly outside the range of pixel values in the input image.  This
%   may also occur for user-specified interpolation kernels.
%
%   Class Support
%   -------------
%   The input image A can be numeric or logical and it must be nonsparse.
%   The output image is of the same class as the input image.  The input
%   indexed image X can be uint8, uint16, or double.
%  
%   See also IMRESIZE3, IMROTATE, IMTRANSFORM, TFORMARRAY.

%   Copyright 1992-2017 The MathWorks, Inc.

%   Note
%   ----
%   The function IMRESIZE changed in version 5.4 (R2007a).  Previous 
%   versions of the Image Processing Toolbox used a somewhat 
%   different algorithm by default.  If you need the same results 
%   produced by the previous implementation, use the function 
%   IMRESIZE_OLD.

args = matlab.images.internal.stringToChar(varargin);
params = parseInputs(args{:});

checkForMissingOutputArgument(params, nargout);

A = preprocessImage(params);

% Determine which dimension to resize first.
order = matlab.images.internal.resize.dimensionOrder(params.scale);

% Calculate interpolation weights and indices for each dimension.
weights = cell(1,params.num_dims);
indices = cell(1,params.num_dims);
allDimNearestNeighbor = true;
for k = 1:params.num_dims
    [weights{k}, indices{k}] = contributions( ...
        size(A, k), ...
        params.output_size(k), params.scale(k), params.kernel, ...
        1, params.antialiasing);
    
    if ~matlab.images.internal.resize.isPureNearestNeighborComputation(weights{k})
        allDimNearestNeighbor = false;
    end
end

if allDimNearestNeighbor
    
    B = matlab.images.internal.resize.resizeAllDimUsingNearestNeighbor(A, indices);
    
else
    B = A;
    for k = 1:numel(order)
        dim = order(k);

        B = resizeAlongDim(B, dim, weights{dim}, indices{dim});
    end
end

[B, map] = postprocessImage(B, params);
%=====================================================================
function [weights, indices] = contributions(in_length, out_length, scale, kernel, kernel_width, antialiasing)
% Convert indexed image to RGB.  Convert binary image to uint8.
if (scale < 1) && (antialiasing)
    % Use a modified kernel to simultaneously interpolate and
    % antialias.
    h = @(x) scale * kernel(scale * x);
    kernel_width = kernel_width / scale;
else
    % No antialiasing; use unmodified kernel.
    h = kernel;
end

% Output-space coordinates.
x = (1:out_length)';

% Input-space coordinates. Calculate the inverse mapping such that 0.5
% in output space maps to 0.5 in input space, and 0.5+scale in output
% space maps to 1.5 in input space.
u = x/scale + 0.5 * (1 - 1/scale);

% What is the left-most pixel that can be involved in the computation?
left = floor(u - kernel_width/2)+1;

% What is the maximum number of pixels that can be involved in the
% computation?  Note: it's OK to use an extra pixel here; if the
% corresponding weights are all zero, it will be eliminated at the end
% of this function.
P = round(kernel_width);

% The indices of the input pixels involved in computing the k-th output
% pixel are in row k of the indices matrix.
indices = bsxfun(@plus, left, 0:P-1);

% The weights used to compute the k-th output pixel are in row k of the
% weights matrix.
weights = ones(size(indices))*scale;
setZero = size(weights,1)*P - in_length;
weights(end,end-setZero+1:end) = 0;

% Normalize the weights matrix so that each row sums to 1.
weights = bsxfun(@rdivide, weights, sum(weights, 2));

% Mirror out-of-bounds indices; equivalent of doing symmetric padding
aux = [1:in_length,in_length:-1:1];
indices = aux(mod(indices-1,length(aux)) + 1);

% If a column in weights is all zero, get rid of it.
kill = find(~any(weights, 1));
if ~isempty(kill)
    weights(:,kill) = [];
    indices(:,kill) = [];
end


%=====================================================================
function A = preprocessImage(params)
% Convert indexed image to RGB.  Convert binary image to uint8.

if isInputIndexed(params)
    A = matlab.images.internal.ind2rgb8(params.A, params.map);
elseif islogical(params.A)
    A = uint8(255) .* uint8(params.A);
else
    A = params.A;
end
%---------------------------------------------------------------------

%=====================================================================
function checkForMissingOutputArgument(params, num_output_args)
% If input image is indexed and the colormap option is optimized, the user
% should be calling the function with two output arguments in order to
% capture the new, optimized colormap.  If the user did not use two output
% arguments, issue a warning message.

if isInputIndexed(params) && strcmp(params.colormap_method, 'optimized') && ...
        (num_output_args < 2)

    warning(message('MATLAB:images:imresize:missingOutputArg'))
end
%---------------------------------------------------------------------

%=====================================================================
function [B,map] = postprocessImage(B_in, params)
% If input was indexed, convert output back to indexed.
% If input was binary, convert output back to binary.

map = [];
if isInputIndexed(params)
    if strcmp(params.colormap_method, 'original')
        map = params.map;
        B = rgb2ind(B_in, map, params.dither_option);
    else
        [B,map] = rgb2ind(B_in, 256, params.dither_option);
    end
    
elseif islogical(params.A)
    B = B_in ==255;
    
else
    B = B_in;
end
%---------------------------------------------------------------------

%=====================================================================
function params = parseInputs(varargin)
% Parse the input arguments, returning the resulting set of parameters
% as a struct.

narginchk(1, Inf);

% Set parameter defaults.
params.kernel = @matlab.images.internal.resize.cubic;
params.kernel_width = 4;
params.antialiasing = [];
params.colormap_method = 'optimized';
params.dither_option = 'dither';
params.num_dims = 2; % This parameter is used to distinguish between 
                     % imresize and imresize3. It is 2 for imresize and 3 
                     % for imresize3.  This way, some methods can be 
                     % generalized for both functions.
params.size_dim = []; % If user specifies NaN for an output size, this
                      % parameter indicates the dimension for which the
                      % size was specified.

method_arg_idx = findMethodArg(varargin{:});

first_param_string_idx = matlab.images.internal.resize.findFirstParamString( ...
    varargin, method_arg_idx);

[params.A, params.map, params.scale, params.output_size] = ...
    parsePreMethodArgs(varargin, method_arg_idx, first_param_string_idx);

if ~isempty(method_arg_idx)
    [params.kernel, params.kernel_width, params.antialiasing] = ...
        parseMethodArg(varargin{method_arg_idx});
end

warnIfPostMethodArgs(varargin, method_arg_idx, first_param_string_idx);

params = parseParamValuePairs(params, varargin, first_param_string_idx);

params = fixupSizeAndScale(params);

if isempty(params.antialiasing)
    % If params.antialiasing is empty here, that means the user did not
    % explicitly specify a method or the Antialiasing parameter.  The
    % default interpolation method is bicubic, for which the default
    % antialiasing is true.
    params.antialiasing = true;
end
    
%---------------------------------------------------------------------

%=====================================================================
function idx = findMethodArg(varargin)
% Find the location of the method argument, if it exists, before the
% param-value pairs.  If not found, return [].

idx = [];
for k = 1:nargin
    arg = varargin{k};
    if ischar(arg)
        if isMethodString(arg)
            idx = k;
            break;
            
        else
            % If this argument is a string but is not a method string, it
            % must be a parameter string.
            break;
        end
        
    elseif iscell(arg)
        idx = k;
        break;
    end
end
%---------------------------------------------------------------------

%=====================================================================
function tf = isMethodCell(in)
% True of the input argument is a two-element cell array containing a
% function handle and a numeric scalar.

tf = iscell(in) && ...
     numel(in) == 2 && ...
     isa(in{1}, 'function_handle') && ...
     isnumeric(in{2}) && ...
     isscalar(in{2});
%---------------------------------------------------------------------

%=====================================================================
function [A, map, scale, output_size] = parsePreMethodArgs(args, method_arg_idx, ...
                                                  first_param_idx)
% Parse all the input arguments before the method argument.

% Keep only the arguments before the method argument.
if ~isempty(method_arg_idx)
    args = args(1:method_arg_idx-1);
elseif ~isempty(first_param_idx)
    args = args(1:first_param_idx-1);
end

% There must be at least one input argument before the method argument.
if numel(args) < 1
    error(message('MATLAB:images:imresize:badSyntaxMissingImage'));
end

% Set default outputs.
map = [];
scale = [];
output_size = [];

A = args{1};
validateattributes(A, {'single', ...
                       'double', ...
                       'int8', ...
                       'int16', ...
                       'int32', ...
                       'uint8', ...
                       'uint16', ...
                       'uint32', ...
                       'logical'}, ...
                      {'nonsparse', ...
                       'nonempty'}, ...
                       mfilename, 'A', 1);

if numel(args) < 2
    return
end

next_arg = 2;
if size(args{next_arg},2) == 3
    % IMRESIZE(X,MAP,...)
    map = args{next_arg};
    matlab.images.internal.iptcheckmap(map, mfilename, 'MAP', 2);
    next_arg = next_arg + 1;
end

if next_arg > numel(args)
    return
end

next = args{next_arg};

% The next input argument must either be the scale or the output size.
[scale, output_size] = scaleOrSize(next, next_arg);
next_arg = next_arg + 1;

if next_arg <= numel(args)
    error(message('MATLAB:images:imresize:badSyntaxUnrecognizedInput', next_arg));
end
%---------------------------------------------------------------------

%=====================================================================
function [scale, output_size] = scaleOrSize(arg, position)
% Determine whether ARG is the scale factor or the output size.

scale = [];
output_size = [];

if isnumeric(arg) && isscalar(arg)
    % Argument looks like a scale factor.
    validateattributes(arg, {'numeric'}, {'nonzero', 'real'}, mfilename, ...
        'SCALE', position);
    scale = double(arg);

elseif isnumeric(arg) && isvector(arg) && (numel(arg) == 2)
    % Argument looks like output_size.
    validateattributes(arg, {'numeric'}, {'vector', 'real', 'positive'}, ...
                  mfilename, '[MROWS NCOLS]', position);
    output_size = double(arg);
    
else
    error(message('MATLAB:images:imresize:badScaleOrSize'));
end
%---------------------------------------------------------------------

%=====================================================================
function [kernel, kernel_width, antialiasing] = parseMethodArg(method)
% Return the kernel function handle and kernel width corresponding to
% the specified method.

[valid_method_names, method_kernels, kernel_widths] = getMethodInfo();

antialiasing = true;

if ischar(method)
    % Replace validatestring here as an optimization. -SLE, 31-Oct-2006
    idx = find(strncmpi(method, valid_method_names, numel(method)));

    switch numel(idx)
      case 0
        error(message('MATLAB:images:imresize:unrecognizedMethodString', method));
        
      case 1
        kernel = method_kernels{idx};
        kernel_width = kernel_widths(idx);
        if strcmp(valid_method_names{idx}, 'nearest')
            antialiasing = false;
        end
        
      otherwise
        error(message('MATLAB:images:imresize:ambiguousMethodString', method));
    end
    
else
    % Cell-array form
    kernel = method{1};
    kernel_width = method{2};
end
%---------------------------------------------------------------------

%=====================================================================
function tf = isMethodString(in)
% Returns true if the input is the name of a method.

if ~ischar(in)
    tf = false;
    
else
    valid_method_strings = getMethodInfo();

    num_matches = sum(strncmpi(in, valid_method_strings, numel(in)));
    tf = num_matches == 1;
end
%---------------------------------------------------------------------

%=====================================================================
function [names,kernels,widths] = getMethodInfo

% Original implementation of getMethodInfo returned this information as
% a single struct array, which was somewhat more readable. Replaced
% with three separate arrays as a performance optimization. -SLE,
% 31-Oct-2006
names = {'nearest', ...
         'bilinear', ...
         'bicubic', ...
         'box', ...
         'triangle', ...
         'cubic', ...
         'lanczos2', ...
         'lanczos3'};

kernels = {@matlab.images.internal.resize.box, ...
           @matlab.images.internal.resize.triangle, ...
           @matlab.images.internal.resize.cubic, ...
           @matlab.images.internal.resize.box, ...
           @matlab.images.internal.resize.triangle, ...
           @matlab.images.internal.resize.cubic, ...
           @matlab.images.internal.resize.lanczos2, ...
           @matlab.images.internal.resize.lanczos3};

widths = [1.0 2.0 4.0 1.0 2.0 4.0 4.0 6.0];
%---------------------------------------------------------------------

%=====================================================================
function warnIfPostMethodArgs(args, method_arg_idx, first_param_string_idx)
% If there are arguments between the method argument and the first
% parameter string, these must be old-style antialiasing syntaxes that
% are no longer supported.  Issue a warning message.  Note that
% either method_arg_idx and first_param_string_idx may be empty.

if isempty(method_arg_idx)
    method_arg_idx = numel(args) + 1;
end

if isempty(first_param_string_idx)
    first_param_string_idx = numel(args) + 1;
end

if (first_param_string_idx - method_arg_idx) > 1
    warning(message('MATLAB:images:imresize:oldSyntaxesIgnored', ...
        'N and H are now ignored in the old syntaxes IMRESIZE(...,method,N) and IMRESIZE(...,method,H).', ...
        'Use IMRESIZE_OLD if you need the previous behavior.'));
end

%---------------------------------------------------------------------

%=====================================================================
function params = parseParamValuePairs(params_in, args, first_param_string)

params = params_in;

if isempty(first_param_string)
    return
end

if rem(numel(args) - first_param_string, 2) == 0
    error(message('MATLAB:images:imresize:oddNumberArgs'));
end

% Originally implemented valid_params and param_check_fcns as a
% structure which was accessed using dynamic field reference.  Changed
% to separate cell arrays as a performance optimization. -SLE,
% 31-Oct-2006
valid_params = {'Scale', ...
                'Colormap', ...
                'Dither', ...
                'OutputSize', ...
                'Method', ...
                'Antialiasing'};

param_check_fcns = {@processScaleParam, ...
                    @processColormapParam, ...
                    @processDitherParam, ...
                    @processOutputSizeParam, ...
                    @processMethodParam, ...
                    @matlab.images.internal.resize.processAntialiasingParam};

for k = first_param_string:2:numel(args)
    param_string = args{k};
    if ~ischar(param_string)
        error(message('MATLAB:images:imresize:expectedParamString', k));
    end
                  
    idx = find(strncmpi(param_string, valid_params, numel(param_string)));
    num_matches = numel(idx);
    if num_matches == 0
        error(message('MATLAB:images:imresize:unrecognizedParamString', param_string));
    
    elseif num_matches > 1
        error(message('MATLAB:images:imresize:ambiguousParamString', param_string));
        
    else
        check_fcn = param_check_fcns{idx};
        params = check_fcn(args{k+1}, params);

    end
end
%---------------------------------------------------------------------

%=====================================================================
function params = processScaleParam(arg, params_in)

valid = isnumeric(arg) && ...
    ((numel(arg) == 1) || (numel(arg) == params_in.num_dims)) && ...
    all(arg > 0);

if ~valid
    error(message('MATLAB:images:imresize:invalidScale'));
end

params = params_in;
params.scale = arg;
%---------------------------------------------------------------------

%=====================================================================
function params = processColormapParam(arg, params_in)

valid = ischar(arg) && (strcmp(arg, 'optimized') || strcmp(arg, 'original'));
if ~valid
    error(message('MATLAB:images:imresize:badColormapOption'));
end

params = params_in;
params.colormap_method = arg;
%---------------------------------------------------------------------

%=====================================================================
function params = processDitherParam(arg, params_in)

valid = (isnumeric(arg) || islogical(arg)) && isscalar(arg);
if ~valid
    error(message('MATLAB:images:imresize:badDitherOption'));
end

params = params_in;
if arg
    params.dither_option = 'dither';
else
    params.dither_option = 'nodither';
end
%---------------------------------------------------------------------

%=====================================================================
function params = processOutputSizeParam(arg, params_in)

valid = isnumeric(arg) && ...
    (numel(arg) == params_in.num_dims) && ...
    all(isnan(arg) | (arg > 0));
if ~valid
    error(message('MATLAB:images:imresize:badOutputSize'));
end

params = params_in;
params.output_size = arg;
%---------------------------------------------------------------------

%=====================================================================
function params = processMethodParam(arg, params_in)

valid = isMethodString(arg) || isMethodCell(arg);
if ~valid
    error(message('MATLAB:images:imresize:badMethod'));
end

params = params_in;
[params.kernel, params.kernel_width, antialiasing] = parseMethodArg(arg);
if isempty(params.antialiasing)
    % Antialiasing hasn't been set explicity in the input arguments
    % parsed so far, so set it according to what parseMethodArg
    % returns.
    params.antialiasing = antialiasing;
end   
%---------------------------------------------------------------------

%=====================================================================
function params = fixupSizeAndScale(params_in)
% If the scale factor was specified as a scalar, turn it into a
% params.num_dims element vector.  If the scale factor wasn't specified,
% derive it from the specified output size.
%
% If the output size has NaN(s) in it, fill in the value(s)
% automatically. If the output size wasn't specified, derive it from
% the specified scale factor.

params = params_in;

if isempty(params.scale) && isempty(params.output_size)
    error(message('MATLAB:images:imresize:missingScaleAndSize'));
end

% If the input is a scalar, turn it into a params.num_dims element vector.
if ~isempty(params.scale) && isscalar(params.scale)
    params.scale = repmat(params.scale, 1, params.num_dims);
end

[params.output_size, params.size_dim] = fixupSize(params);

if isempty(params.scale)
    params.scale = matlab.images.internal.resize.deriveScaleFromSize(params);
end

if isempty(params.output_size)
    params.output_size = matlab.images.internal.resize.deriveSizeFromScale(params);
end
%---------------------------------------------------------------------

%=====================================================================
function [output_size, size_dim] = fixupSize(params)
% If params.output_size has a NaN in it, calculate the appropriate
% value to substitute for the NaN.

output_size = params.output_size;
size_dim = [];

if ~isempty(output_size)
    if ~all(output_size)
        error(message('MATLAB:images:imresize:zeroOutputSize'));
    end
    
    if all(isnan(output_size))
        error(message('MATLAB:images:imresize:allNaN'));
    end
    
    if isnan(output_size(1))
        output_size(1) = params.output_size(2) * size(params.A, 1) / ...
            size(params.A, 2);
        size_dim = 2;
        
    elseif isnan(output_size(2))
        output_size(2) = params.output_size(1) * size(params.A, 2) / ...
            size(params.A, 1);
        size_dim = 1;
        
    end
    
    output_size = ceil(output_size);
end
%---------------------------------------------------------------------

%=====================================================================
function tf = isInputIndexed(params)

tf = ~isempty(params.map);
%---------------------------------------------------------------------

%=====================================================================
function out = resizeAlongDim(in, dim, weights, indices)
% Resize along a specified dimension
%
% in           - input array to be resized
% dim          - dimension along which to resize
% weights      - weight matrix; row k is weights for k-th output pixel
% indices      - indices matrix; row k is indices for k-th output pixel

if matlab.images.internal.resize.isPureNearestNeighborComputation(weights)
    out = matlab.images.internal.resize.resizeAlongDimUsingNearestNeighbor(in, ...
        dim, indices);
    return
end

out_length = size(weights, 1);

size_in = size(in);
size_in((end + 1) : dim) = 1;

if (ndims(in) > 3)
    % Reshape in to be a three-dimensional array.  The size of this
    % three-dimensional array is the variable pseudo_size_in below.
    %
    % Final output will be consistent with the original input.
    pseudo_size_in = [size_in(1:2) prod(size_in(3:end))];
    in = reshape(in, pseudo_size_in);
end

% The 'out' will be uint8 if 'in' is logical 
% Otherwise 'out' datatype will be same as 'in' datatype
out = matlab.images.internal.resize.imresizemex(in, weights', indices', dim);

if ( (length(size_in) > 3) && (size_in(end) > 1) )
    % Restoring final output to expected size
    size_out = size_in;
    size_out(dim) = out_length;
    out = reshape(out, size_out);
end
%---------------------------------------------------------------------
