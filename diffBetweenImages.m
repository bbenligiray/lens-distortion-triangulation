% calculates RMSE and PSNR between a large and a small image.
%   convolves the smaller image accross the larger image,
%   crops the larger image where they align the best.
%   we are doing this in case any of the methods translate the image.

function [rmse, psnr] = diffBetweenImages(imgLarge, imgSmall)

if size(imgLarge) ~= size(imgSmall)
    imgLarge = alignImage(imgLarge, imgSmall);
end

rmse = sqrt(mean2((imgSmall - imgLarge) .^ 2));

hpsnr = vision.PSNR;
psnr = step(hpsnr, imgSmall, imgLarge);

% crops the larger image with the best alignment to the small image
function imgAligned = alignImage(imgLarge, imgSmall)
% crop the larger image from the center with roughly this much padding
padding = 10;

% middle point of the large image
midPoint = floor(size(imgLarge) / 2);
% half size of the small image
sizeHalf = floor(size(imgSmall) / 2);

% crop the larger image once, leaving just enough for the sliding
halfHeightImgCropped = sizeHalf(1) + padding;
halfWidthImgCropped = sizeHalf(2) + padding;
imgCropped = imgLarge(midPoint(1) - halfHeightImgCropped:midPoint(1) + halfHeightImgCropped,midPoint(2) - halfWidthImgCropped:midPoint(2) + halfWidthImgCropped);

% decide on the number of slides based on the cropped image's size
noSlideY = size(imgCropped, 1) - size(imgSmall, 1) + 1;
noSlideX = size(imgCropped, 2) - size(imgSmall, 2) + 1;

% find the slide that gives the smallest error
minRMSE=Inf;
for indSlideY = 1:noSlideY
	for indSlideX = 1:noSlideX
        % crop the large image again
		imgCroppedTwice = imgCropped(indSlideY:size(imgSmall,1) + indSlideY - 1,indSlideX:size(imgSmall, 2) + indSlideX - 1);
        % calculate MSE, save indices if fits better
		currMSE = mean2((imgCroppedTwice - imgSmall) .^ 2);
		if currMSE < minRMSE
			minRMSE = currMSE;
            imgAligned = imgCroppedTwice;
		end
	end
end
