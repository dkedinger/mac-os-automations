# Resize Images

Right-click one or more images in Finder, then choose **Quick Actions → Resize Images**.

A single dialog lets you choose:

- **Limit by:** Maximum width or Maximum height
- **Maximum size:** Any whole-pixel value (defaults to 1600)
- **Resolution:** 72 DPI (default), 150 DPI, or 300 DPI

The action preserves each image's aspect ratio and never enlarges an image that is already below the selected maximum. It changes the selected files in place, including their DPI metadata, so duplicate important originals first if you want to keep them unchanged.

## Install

1. Unzip `Resize Images.zip`.
2. Double-click `Resize Images.workflow`.
3. Click **Install**.
4. In Finder, select images and use **Quick Actions → Resize Images**.

The action uses macOS's built-in `sips` image tool and requires no additional software.

## Supported images

Finder offers the action for files macOS identifies as images. Formats that `sips` can read and write—such as JPEG, PNG, TIFF, GIF, HEIC, and BMP—are supported. If macOS cannot update a selected file, the action reports its filename without stopping the other images.

The readable source embedded in the workflow is also saved as [`script.zsh`](script.zsh).
