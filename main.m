% This is a test script that:
%	Reads test images (these shouldn't be compressed with any loss),
%	Applies degrees of lens distortions to the test images using undistortClassic(),
%	Undistorts the distorted images with various methods,
%	Compares their RMSE and PSNR.


% read the images
% they are all assumed to be of the same resolution
noImage = 10;
images = cell(noImage,1);
for indImage = 1:noImage
	images{indImage} = rgb2gray(imread(['images\imraw' num2str(indImage) '.bmp']));
end


% this struct keeps the camera and distortion parameters
% the distortion parameters are 0, they will be set later
invParams = struct('fx',1, 'fy', 1, 'cx', size(images{1}, 2) / 2, 'cy', size(images{1}, 1) / 2, 'k1', 0, 'k2', 0);


% k1 and k2 are the radial distortion parameters
% k1 value will change between k1Max and k1Min
% k2 will be derived from k1 using k2tok1Ratio
k1Max = 1 * 10^-11;
k1Min = 1 * 10^-13;

k2tok1Ratio = 0.2;
k2Max = k1Max * k2tok1Ratio;
k2Min = k1Min * k2tok1Ratio;

% put the distortion parameters to be tested in a matrix
noDistStep = 10;
stepk1 = (k1Max-k1Min) / (noDistStep - 1);
stepk2 = (k2Max-k2Min) / (noDistStep - 1);

distParamSet = zeros(noDistStep, 2);
for indStep = 1:noDistStep
	distParamSet(indStep, :) = [k1Max - (indStep-1) * stepk1, k2Max - (indStep-1) * stepk2];
end

% create containers for the results
methods = {'Triangulation w/ inverse parameters',
    'Newton-Raphson, 1 iteration',
    'Newton-Raphson, 5 iterations',
    'Custom inverse model'};
noMethods = size(methods,1);
runTimes = zeros(noMethods, 1);
rmseScores = zeros(noImage, noDistStep, noMethods);
psnrScores = zeros(noImage, noDistStep, noMethods);

% start the test
for indImage = 1:noImage
	for indDistStep = 1:noDistStep
        disp(['Image index: ' num2str(indImage) ' Distortion step: ' num2str(indDistStep)]);
		
		% set the current distortion parameters
		invParams.k1 = distParamSet(indDistStep, 1);
		invParams.k2 = distParamSet(indDistStep, 2);
		
		% apply synthetic distortion
        disp(['Applying synthethic distortion with k1: ' num2str(invParams.k1) ' k2: ' num2str(invParams.k2)]);
		imgSynthDist = im2uint8(undistortClassic(im2double(images{indImage}), invParams));
        
        % undistort with different methods and calculate rmse, psnr
        disp(['Undistorting with method: ' methods{1}]);
        tic;
        imgUndist = undistortTriangulate(imgSynthDist, invParams, 'linearDelaunay');
        runTimes(1) = runTimes(1) + toc;
        [rmseScores(indImage, indDistStep, 1), psnrScores(indImage, indDistStep, 1)] = diffBetweenImages(imgUndist, images{indImage});
        
        disp(['Undistorting with method: ' methods{2}]);
        tic;
        imgUndist = undistortNewton(imgSynthDist, invParams, 1);
        runTimes(2) = runTimes(2) + toc;
        [rmseScores(indImage, indDistStep, 2), psnrScores(indImage, indDistStep, 2)] = diffBetweenImages(imgUndist, images{indImage});
        
        tic;
        disp(['Undistorting with method: ' methods{3}]);
        imgUndist = undistortNewton(imgSynthDist, invParams, 5);
        runTimes(3) = runTimes(3) + toc;
        [rmseScores(indImage, indDistStep, 3), psnrScores(indImage, indDistStep, 3)] = diffBetweenImages(imgUndist, images{indImage});
        
        tic;
        disp(['Undistorting with method: ' methods{4}]);
        imgUndist = undistortCustomInverse(imgSynthDist, invParams);
        runTimes(4) = runTimes(4) + toc;
        [rmseScores(indImage, indDistStep, 4), psnrScores(indImage, indDistStep, 4)] = diffBetweenImages(imgUndist, images{indImage});
	end
end

% display the results
runTimes = runTimes / (noImage * noDistStep);
for indMethod = 1:4
    disp([methods{indMethod} ' running time: ' num2str(runTimes(indMethod))]);
end

meanRMSE = mean(rmseScores);
figure;
set(gca, 'xdir', 'reverse');
xlabel('Lens Distortion Parameter (K1)');
ylabel('RMSE');
hold on;
for indMethod = 1:4
    plot(distParamSet(:,1), meanRMSE(1, :, indMethod));
end
legend(methods{1}, methods{2}, methods{3}, methods{4});

meanPSNR = mean(psnrScores);
figure;
set(gca, 'xdir', 'reverse');
xlabel('Lens Distortion Parameter (K1)');
ylabel('PSNR');
hold on;
for indMethod = 1:4
    plot(distParamSet(:,1), meanPSNR(1, :, indMethod));
end
legend(methods{1}, methods{2}, methods{3}, methods{4});