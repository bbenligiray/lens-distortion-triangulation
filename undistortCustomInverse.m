% undistorts by estimating the custom inverse model parameters

% J. Mallon and P. F. Whelan, “Precise radial un-distortion of images,” in
% Proc. IEEE Int. Conf. Pattern Recognition (ICPR), 2004.

% we use the model in Equation 5 with a twist,
% we swap the distorted and undistorted points.
function imgUndist = undistortCustomInverse(imgDist, invParams)

width = size(imgDist, 2);
height = size(imgDist, 1);

% set up the camera matrix and inverse distortion parameters
K = [invParams.fx 0 invParams.cx;
	0 invParams.fy invParams.cy;
	0 0 1];
invK = inv(K);
k1 = invParams.k1;
k2 = invParams.k2;

% a terribly convenient way of creating a list of pixel indices
[yIndices, xIndices] = find(~isnan(imgDist));

% apply the inverse of the camera matrix to homogeneous coordinates
hPoints = invK * [xIndices yIndices ones(length(xIndices),1)]';

% create a list of pixels from the undistorted image ...
xUndist = hPoints(1,:)';
yUndist = hPoints(2,:)';
r2Undist = xUndist.^2 + yUndist.^2; % radius-squared
% ... and the corresponding points in the distorted image
xDist = xUndist .* (1 + k1 * r2Undist + k2 * r2Undist.^2);
yDist = yUndist .* (1 + k1 * r2Undist + k2 * r2Undist.^2);
r2Dist = xDist.^2 + yDist.^2;

% we set up everything here, so that the optimization iterations are as
% light as possible
noPixels = size(r2Dist, 1);

A = zeros(noPixels * 2, 6);
b = zeros(noPixels * 2, 1);

for indPixel = 1:noPixels
    A(indPixel * 2 - 1, :) = [
        xUndist(indPixel) * r2Undist(indPixel)
        xUndist(indPixel) * r2Undist(indPixel)^2
        xUndist(indPixel) * r2Undist(indPixel)^3
        xUndist(indPixel) * r2Undist(indPixel)^4
        (xDist(indPixel) - xUndist(indPixel)) * r2Undist(indPixel)
        (xDist(indPixel) - xUndist(indPixel)) * r2Undist(indPixel)^2
        ];
    A(indPixel * 2, :) = [
        yUndist(indPixel) * r2Undist(indPixel)
        yUndist(indPixel) * r2Undist(indPixel)^2
        yUndist(indPixel) * r2Undist(indPixel)^3
        yUndist(indPixel) * r2Undist(indPixel)^4
        (yDist(indPixel) - yUndist(indPixel)) * r2Undist(indPixel)
        (yDist(indPixel) - yUndist(indPixel)) * r2Undist(indPixel)^2
        ];
    b(indPixel * 2 - 1) = xDist(indPixel) - xUndist(indPixel);
	b(indPixel * 2) = yDist(indPixel) - yUndist(indPixel);
end

% nonlinearly optimize the model parameters
custParams = zeros(6,1);
custParams = fminsearch(@funToSolve, custParams, '', A, b);

% maps between the undistorted image and the distorted image
xInterpList = zeros(height, width);
yInterpList = zeros(height, width);

indRunning = 1; % a running counter for convenience
for indX = 1:width
    for indY = 1:height
        % these are the pixels of the undistorted image, multiplied by invK
        xToMap = xUndist(indRunning);
        yToMap = yUndist(indRunning);
        r2ToMap = r2Undist(indRunning);
        % use the custom model to find where this pixel maps to
        xMapped = xToMap - xToMap * ((custParams(1) * r2ToMap + custParams(2) * r2ToMap^2 + custParams(3) * r2ToMap^3 + custParams(4) * r2ToMap^4) / (1 + custParams(5) * r2ToMap + custParams(6) * r2ToMap^2));
        yMapped = yToMap - yToMap * ((custParams(1) * r2ToMap + custParams(2) * r2ToMap^2 + custParams(3) * r2ToMap^3 + custParams(4) * r2ToMap^4) / (1 + custParams(5) * r2ToMap + custParams(6) * r2ToMap^2));
        
        % reapply K
        pMapped = K * [xMapped yMapped 1]';
        xDist=pMapped(1);
        yDist=pMapped(2);
        
        % fill the map in
        xInterpList(indY, indX) = xDist;
        yInterpList(indY, indX) = yDist;
        indRunning = indRunning + 1;
    end
end

imgUndist = uint8(interp2(double(imgDist), xInterpList, yInterpList));

function error = funToSolve(params, A, b)

error = mean((A * params + b).^2);

