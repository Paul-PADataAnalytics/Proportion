# Proportion
A app that adds a grid to images to better sketch an image.  The app is called Proportion.

The app is written in Dart and uses the Flutter framework.

The app runs on Android, Linux, Windows, and via a web app.

## Features
- Add a grid to an image
- Export the image back to the users OS
- Select parts of the grid to add a further subdivided grid to assist in detailed areas
- Select parts to reduce the subdivision of the grid to assist in larger areas where no detail is needed

## Android Features
- as above
- added camera mode to allow taking a photo and immediately add a grid to it
- Packaged app for Android as a sideloadable APK
- Packaged app for Android as an AAB for the Google Play Store

## Linux Features
- as above
- added file picker to allow selecting an image from the users OS
- added file picker to allow selecting a folder to save the image to
- Packaged app for Linux as an AppImage

## Windows Features
- as above
- added file picker to allow selecting an image from the users OS
- added file picker to allow selecting a folder to save the image to
- Packaged app for Windows and Windows Store

## Web Features
- as above
- added file picker to allow selecting an image from the users OS
- added file picker to allow selecting a folder to export the image to
- only operating on the client side for privacy
- Packaged app for Web as a PWA

## UI
Using the flutter material design language, the app has a simple and intuitive UI based around opening images and adding a grid to them.

The main part of the app is the area where images are displayed and edited.

The top of the screen is a toolbar that allows the user to open images, select the grid size in pixels, the subgrid size in pixels, and export the image.

The app respects the users existing OS preferences for dark mode and light mode.

The app has a set of default grid sizes that are easily accessible, but the user can also set their own grid sizes.

### The Grid

The grid is a set of colinear, and tangent lines that are repeated at regular intervals.  The grid is added to the canvas and can be scaled, moved, and rotated around the canvas, with selective subdivision of the grid.  The grid colour, and that of the subgrid can be set by the user.

The grid is not applied to the original image, but is instead added as a layer on top of the image until the user exports the image where it is finally composited with the original image.

The grid can be sized in terms of pixels from the top left of the image, or as a function of the width and height of the image in the form of height and width of the grid as a percentage of the image.

#### Circular Grid

An extra, alternative mode of adding grids is availble with circular grids.  This mode is selected by the user in the toolbar.

A circular grid is defined as concentric circles from a single point in the image where the circles are spaced at a chosen interval.  This circular grid has multiple segments running from the centre to the most outer ring of the circular grid.  A subgrid of segments and rings can also be added to rings of the circular grid to assist in detailed areas.


The image can be exported back to the users OS as a PNG file.  The original image is not modified, but instead the grid is composited with the original image and exported as a PNG file with the original file name and the suffix "_gridded" added to it.

## V2 Features
- **Responsive Toolbar**: Automatically positions the toolbar (bottom or right) based on screen orientation and aspect ratio.
- **Direct Manipulation**:
    - **Scale**: Pinch to zoom (Touch) or Mouse Wheel (Desktop).
    - **Move**: Drag to pan grid.
    - **Rotate**: Twist (Touch) or Right-Click Drag (Desktop).
- **Advanced Grid Modes (V3)**:
    - **Square**: Fixed cell size.
    - **Square (Fixed)**: Fixed column count.
    - **Rectangle**: Width/Height control.
    - **Rectangle (Fixed)**: Columns/Rows control.
    - **Circle**: Radial sizing and segments.
- **Improved Export**: Export to PNG, JPG, or PDF.