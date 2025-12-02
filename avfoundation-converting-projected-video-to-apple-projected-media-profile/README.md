# Converting projected video to Apple Projected Media Profile

Convert content with equirectangular or half-equirectangular projection to APMP.

## Overview

- Note: This sample code project is associated with WWDC25 session 297: [Learn about the Apple Projected Media Profile](https://developer.apple.com/videos/play/wwdc2025/297).

## Configure the sample code project
    
The app takes a path to a monoscopic or stereoscopic (frame-packed) side-by-side or over-under stereo input video file as a single command-line argument. To run the app in Xcode, click the Run button to convert the included side-by-side frame-packed stereoscopic 180 sample asset (`Lighthouse_sbs.mp4`), or choose Product > Scheme > Edit Scheme, and edit the path to your file on the Arguments tab of the Run build scheme action.

To add projected media metadata to an output file, pass one of the following two options:

- term `--autoDetect` (or `-a`): Examines the source file for spherical metadata compatible with APMP.
- term `--projectionKind <projection_kind>` (or `-p`): Specifies the projection type, which can be `equirectangular` or `halfequirectangular`.

Other options:
- term `--viewPackingKind <view_packing_kind>` (or `-v`): Manually specifies the frame-packing mode, which can be `sidebyside` or `overunder`. The app ignores this option if you specify the `--autoDetect` option.
- term `--baseline` (or `-b`): Specifies a baseline in millimeters (for example, `--baseline 64.0` for a 64mm baseline).
- term `--fov` (or `-f`): Specifies a horizontal field of view in degrees (for example, `--fov 80.0` for an 80-degree field of view).

By default, the project's scheme loads a side-by-side video from the Xcode project folder named `Lighthouse_sbs.mp4`. 


