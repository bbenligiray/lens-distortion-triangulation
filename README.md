## Lens Distortion Rectification using Triangulation based Interpolation

Code used in the following paper:

[Benligiray, B.; Topal, C., "Lens distortion rectification using triangulation based interpolation," International Symposium on Visual Computing (ISVC), 2015.](https://arxiv.org/abs/1611.09559)

#### What is this?

Lens distortion rectification methods, e.g., OpenCV's undistort(), use the forward distortion parameters.
Self-calibration methods estimate the inverse distortion parameters.
The traditional approach then, is to approximate the forward distortion parameters using the inverse distortion parameters, and use the existing rectification methods.
We propose a method for rectification using the inverse distortion parameters directly, which gives more accurate results.

#### Running time

I didn't optimize the code to work in real-time, e.g., to rectify frames captured sequentially from a camera. Here are some pointers if you would like to do that:

With the proposed method, 3 pixels of the distorted image vote on each pixel of the rectified image with respective weights (see the figure below).
Instead of running the entire algorithm for each frame, one should calculate this mapping once and use it to rectify all frames, as the contents of the images don't affect the rectification.
This is akin to using initUndistortRectifyMap()+remap() instead of undistort() with OpenCV.

<p align="center">
  <img src="https://cloud.githubusercontent.com/assets/19530665/21472106/48addb86-cadb-11e6-966c-402dae84078c.png"/>
</p>
