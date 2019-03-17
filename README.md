# roav_uploader
## ROAV Dashcam C1 Pro Uploader script for Mapillary and OpenStreetCam

The script takes the ROAV dashcam video, converts it to individual jpeg images, adds geotags and then uploads to Mapillary and OpenStreetCam.
Features include not transmitting images near a point, such as your home and not transmitting images if there is little or no movement, i.e. your car isn't moving.

Latest update speeds processing up by not having to copy source video to working directory.

#### Requirements:
* ffmpeg
* exiftool
* [Mapillary Tools](https://github.com/mapillary/mapillary_tools)
* [OpenStreetCam upload script](https://github.com/openstreetcam/upload-scripts)
* Bash
* gawk

#### Installation
Move roav.config to your home directory and modify it to include your home location latitude and longitude, the working directory location and your Mapillary user name.

Move roav_uploader.sh to a directory in your $PATH such as /usr/local/bin. Move src/roav to tool_dir specified in roav.config.
