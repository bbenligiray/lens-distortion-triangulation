% undistorts the image "directly" using the inverse distortion parameters

function imgUndist = undistortTriangulate(imgDist, invParams, method)

% a terribly convenient way of creating a list of pixel indices
[yIndices, xIndices] = find(~isnan(imgDist));

% set up the camera matrix and inverse distortion parameters
K = [invParams.fx 0 invParams.cx;
	0 invParams.fy invParams.cy;
	0 0 1];
invK = inv(K);
k1 = invParams.k1;
k2 = invParams.k2;

% apply the inverse of the camera matrix to homogeneous coordinates
hPoints = invK * [xIndices yIndices ones(length(xIndices),1)]';

% calculate the non-linear mapping
r2 = hPoints(1,:).^2 + hPoints(2,:).^2; % radius-squared
x = hPoints(1,:);
y = hPoints(2,:);

x = x .* (1 + k1 * r2 + k2 * r2.^2);
y = y .* (1 + k1 * r2 + k2 * r2.^2);


% get a list of pixel values of the distorted image
pixVals = double(imgDist(1:numel(imgDist)));

% find out the maximum size along each axis
minX = floor(min(x));
maxX = ceil(max(x));
maxX = max(abs(minX), maxX);
minY = floor(min(y));
maxY = ceil(max(y));
maxY = max(abs(minY), maxY);

% fill in the pixel indices for the output image
arrX = -maxX:maxX;
arrY = -maxY:maxY;

indY = zeros(length(arrX) * length(arrY),1);
indX = indY;

for ind=1:length(arrX)
    indY((ind - 1) * length(arrY) + 1:ind * length(arrY)) = arrY;
end
for ind=1:length(arrX)
    indX((ind - 1) * length(arrY) + 1:ind * length(arrY)) = ones(1, length(arrY)) * arrX(ind);
end

% do the interpolation
if strcmp(method, 'linearDelaunay')
    vals = uint8(griddata(x, y, pixVals, indX, indY, 'linear'));
elseif strcmp(method, 'cubicDelaunay')
    vals = uint8(griddata(x, y, pixVals, indX, indY, 'cubic'));
elseif strcmp(method, 'biharmonicSpine')
    vals = uint8(griddata(x, y, pixVals, indX, indY, 'v4'));
end

% reshape into a matrix
imgUndist = reshape(vals, [(2 * maxY + 1),(2 * maxX + 1)]);