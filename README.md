# roav_uploader
## ROAV Dashcam C1 Pro Uploader script for Mapillary and OpenStreetCam

The script takes the ROAV dashcam video, converts it to individual jpeg images, adds geotags and then uploads to Mapillary and OpenStreetCam.
Features include not transmitting images near a point, such as your home and not transmitting images if there is little or no movement, i.e. your can isn't moving.

Requirments:
* ffmpeg
* exiftool
* [Mapillary Tools](https://github.com/mapillary/mapillary_tools)
* [OpenStreetCam upload script](https://github.com/openstreetcam/upload-scripts)
