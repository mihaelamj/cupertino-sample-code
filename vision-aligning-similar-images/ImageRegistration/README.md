#  Aligning Similar Images

Align images that contain the same scene captured from slightly different viewpoints.

## Overview

This sample app uses Vision Framework's image registration requests to calculate an alignment transform between two images of the same scene that are slightly offset and warped from one another. The sample app uses the alignment transform to construct a single, composite image that contains the aligned content of both images.

## Provide Input Images

Image registration requests require two images, a reference image and a floating image. The best alignment occurs when the content of the input images are very similar. In this sample app, the input images are nearly identical. One image has been offset and warped slightly from the other image to simulate an image capture of the same scene from a slightly different position. This sample app displays the input images next to the aligned composite image for visual comparison in the `registrationImages` view.

## Select a Registration Mechanism

Vision provides a translational image registration mechanism, [`VNTranslationalImageRegistrationRequest`][translational_reg], and a homographic image registration mechanism, [`VNHomographicImageRegistrationRequest`][homographic_reg]. This sample app provides a toggle between these two image registration mechanisms to visually demonstrate the differences in their image alignment observations.

## Apply the Alignment Observation

This project applies the alignment observation for each different image registration mechanism in the [`register`](x-source-tag://Register) function and returns an image containing the composited result. The
[`register`](x-source-tag://Register) function uses the [`makeAlignedImage`](x-source-tag://MakeAlignedImage) function to transform the floating image.  The sample uses the [transformed(by:)](https://developer.apple.com/documentation/coreimage/ciimage/1438203-transformed) method to apply the translational transform when the translational image registration mechanism is used.  The sample uses the [CIPerspectiveTransform](https://developer.apple.com/documentation/coreimage/ciperspectivetransform) filter to apply the pespective transform when the homographic image registration mechanism is used.

[translational_reg]:https://developer.apple.com/documentation/vision/vntranslationalimageregistrationrequest
[homographic_reg]:https://developer.apple.com/documentation/vision/vnhomographicimageregistrationrequest

