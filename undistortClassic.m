% this function can either be used to undistort an image using the distortion parameters (what we won't do),
% or apply distortion to an image using the inverse of the distortion parameters (what we will do)

% the output image is the same size as the input image
% supports up to 2 radial parameters (k1, k2), can be extended

function imgUndist = undistortClassic(imgDist, params)

% the steps are as follows:
% 1 - apply the inverse of the camera matrix
% 2 - distort/undistort
% 3 - reapply the camera matrix

% a terribly convenient way of creating a list of pixel indices
[yIndices, xIndices] = find(~isnan(imgDist));

% set up the camera matrix
K = [params.fx 0 params.cx;
	0 params.fy params.cy;
	0 0 1];

% apply the inverse of the camera matrix to homogeneous coordinates
hPoints = inv(K) * [xIndices yIndices ones(length(xIndices),1)]';

% calculate the non-linear mapping
r2 = hPoints(1,:).^2 + hPoints(2,:).^2; % radius-squared
x = hPoints(1,:);
y = hPoints(2,:);

x = x .* (1 + params.k1 * r2 + params.k2 * r2.^2);
y = y .* (1 + params.k1 * r2 + params.k2 * r2.^2);

% tangential distortion can be added as follows:
% https://en.wikipedia.org/wiki/Distortion_(optics)#Software_correction
% x = x.*(1+params.k1*r2 + params.k2*r2.^2) + 2*params.p1.*x.*y + params.p2*(r2 + 2*x.^2);
% y = y.*(1+params.k1*r2 + params.k2*r2.^2) + 2*params.p2.*x.*y + params.p1*(r2 + 2*y.^2);

% reapply the camera matrix, reshape for interp2
u = reshape(params.fx*x + params.cx, size(imgDist));
v = reshape(params.fy*y + params.cy, size(imgDist));

% apply mapping
imgUndist = interp2(imgDist, u, v);