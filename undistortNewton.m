% estimates the inverse of the mapping using the Newton-Raphson method
% if noIter == -1, repeats until the result doesn't change

function imgUndist = undistortNewton(imgDist, invParams, noIter)

% create the output image
width = size(imgDist, 2);
height = size(imgDist, 1);

imgUndist = uint8(zeros(height, width));

% set up the camera matrix and inverse distortion parameters
K = [invParams.fx 0 invParams.cx;
	0 invParams.fy invParams.cy;
	0 0 1];
invK = inv(K);
k1 = invParams.k1;
k2 = invParams.k2;

% for each pixel of the rectified image, we will estimate where we should
% sample in the distorted image using the Newton-Raphson method.
for indX = 1:width
	for indY = 1:height
         % the iteration is initialized at (indX,indY) and the
         % corresponding r
		hPoints = invK * [indX indY 1]';
		xDist = hPoints(1);
		yDist = hPoints(2);
		rDist = sqrt(xDist^2 + yDist^2);
        r = rDist;
        
		% we find the real r by iteration
        
        % if noIter == -1, repeats until the result doesn't change
        if noIter == -1
            rDistOld = 0;
            while rDistOld ~= rDist
                rDistOld = rDist;
                rDist = rDist - (rDist + k1 * rDist^3 + k2 * rDist^5 - r)/(1 + 3 * k1 * rDist^2 + 5 * k2 * rDist^4);
            end
        % if noIter ~= -1, iterates noIter times
        else
            for countIter = 1:noIter
                rDist = rDist - (rDist + k1 * rDist^3 + k2 * rDist^5 - r)/(1 + 3 * k1 * rDist^2 + 5 * k2 * rDist^4);
            end
        end
        % find where we should sample using the estimated rDist
        xDist = xDist / (1 + k1 * rDist^2 + k2 * rDist^4);
		yDist = yDist / (1 + k1 * rDist^2 + k2 * rDist^4);
		
        % reapply the camera matrix
        hPoints = K * [xDist yDist 1]';
        
        xDist = hPoints(1);
        yDist = hPoints(2);
		
        % if the point to be sampled is outside the distorted image, skip
        if (floor(xDist) < 1) || (floor(yDist) < 1) || (ceil(xDist) > width) || (ceil(yDist) > height)
            continue;
        end
        
        % sample by bilinear interpolation
        interPoint = zeros(4, 2);
		interPoint(1, :) = [floor(xDist) floor(yDist)];
		interPoint(2, :) = [floor(xDist) ceil(yDist)];
		interPoint(3, :) = [ceil(xDist) floor(yDist)];
		interPoint(4, :) = [ceil(xDist) ceil(yDist)];
		
        interDists = zeros(4, 1);
        for indDist = 1:4
            interDists(indDist) = sqrt((interPoint(indDist, 1) - xDist)^2 + (interPoint(indDist, 2) - yDist)^2);
        end
        interDists = interDists ./ sum(interDists);
        
        sampleVal = 0;
        for indSample = 1:4
            sampleVal = sampleVal + double(imgDist(interPoint(indSample, 2),interPoint(indSample, 1))) * interDists(indSample);
        end
		
		imgUndist(indY, indX) = round(sampleVal);
	end
end