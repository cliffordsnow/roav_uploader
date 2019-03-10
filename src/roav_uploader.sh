#!/bin/bash

usage() {
	echo "Usage: $0 [-h help][-r rerun mapillary ][-s mapillary|osc] [-c crop] [-b buffer] [d stop] [-t test only]  video_file" 1>&2
}

exit_abnormal() {
	usage
	exit 1
}

get_image_size() {
	image_size=`exiftool ${video}.MP4 | gawk -F ":" '/Image Size/ {print $2}'`
	echo $image_size
}

source roav.config
oscexp='^[Oo][Ss][Cc]$'
mapexp='^[Mm][Aa][Pp][Ii][Ll][Ll][Aa][Rr][Yy]$'
crop='^[0-9]+[xX][0-9]+$'
decimal='^[0-9]*\.[0-9]+$'

while getopts "s:c:b:d:rth" options
do
	case ${options} in
		s) SERVICE=${OPTARG}
			if [[ $SERVICE =~ $oscexp  ]]
			then
				SERVICE="OSC"
			elif [[ $SERVICE =~ $mapexp ]]
			then
				SERVICE="MAPILLARY"
			else
				echo "Error: must match either OSC or MAPILLARY"
				exit_abnormal
			fi
			 ;;
		c) CROP=${OPTARG}
			if ! [[ $CROP =~ $cropexp ]]
			then
				echo "-c must contain width X height for example -c 1000X700"
				exit_abnormal
			fi
			;;
		b) BUFFER=${OPTARG}
			if ! [[ $BUFFER =~ $decimal ]]
			then
				echo "Error: must be a decimal value."
				exit_abnormal
			fi
			;;
		d) SPEED=${OPTARG}
			if ! [[ $SPEED =~ $decimal ]]
			then
				echo "Error: must be a decimal value."
				exit_abnormal
			fi
			;;
		r) RERUNOPT=" --rerun "
			;;
		t) TEST=true
			;;
		h|?) usage
			;;
	esac
done

shift $((OPTIND-1))

#now we need video file as $1
if [ "$#" -ne 1 ]
then
	echo "Error no video file"
        exit_abnormal
fi


input_file=`echo $1|sed -e 's/.MP4//'`
video=`basename -s .MP4 $1`

if ! [ -d $WORKINGDIR ]
then
	mkdir -p $WORKINGDIR
fi

if ! [ -d ${WORKINGDIR}/jpeg ]
then
	mkdir ${WORKINGDIR}/jpeg
fi

if ! [ -d ${WORKINGDIR}/output ]
then
	mkdir ${WORKINGDIR}/output
fi

#this is for testing purposes
#change to mv for production version


cp ${input_file}.MP4 $WORKINGDIR
cp ${input_file}.info $WORKINGDIR


cd $WORKINGDIR

rm jpeg/*
rm output/*
rm *.csv


video_no=`echo $video|sed -e 's/^20.._...._......_//'`


#Creation of the .csv file for geocoding images
gawk -f info2csv.awk ${video}.info > ${video_no}.csv

frames=`cat ${video}.info|wc -l`

#Cropping  1280x720 image to 1920x900`
#get image size
get_image_size
echo ${image_size} | wc -c
echo "xxx${image_size}xxx"

if [ $CROP ]; then
	crop=`echo $CROP | tr "[xX]" ":"`
	echo "Cropping ${image_size} image to ${crop}"
	ffmpeg -i ${video}.MP4 -ss 00:00:01 -t ${frames} -r 1 -vf "crop=${crop}" jpeg/${video_no}_%03d.jpeg
else
       if [[ "${image_size}" == " 1280x720" ]]; then
		echo "Cropping ${image_size} image to 1220x520"
		ffmpeg -i ${video}.MP4 -ss 00:00:01 -t ${frames} -r 1 -vf "crop=1220:520" jpeg/${video_no}_%03d.jpeg
	else
		echo "Cropping ${image_size} image to 1920x900"
		ffmpeg -i ${video}.MP4 -ss 00:00:01 -t ${frames} -r 1 -vf "crop=1920:900" jpeg/${video_no}_%03d.jpeg
	fi
fi

# Now we need to add the geotags to each image.
# exiftool makes it easy to geotag a folder of images. The key is the creation of the .csv file which occured earlier.

exiftool -DateTimeOriginal -GPSLatitude -GPSLongitude -GPSAltitude -GPSspeed -GPSimagedirection -GPSLatitudeRef -GPSLongitudeRef -GPSAltitudeRef -csv=${video_no}.csv -o output/ jpeg/

#remove images near home
#need to create a optarg for boundary size

echo "Pruning out files within buffer distance"
python /Volumes/SD256/ROAV/foo/distance.py ${video_no}.csv $HOMELAT $HOMELON $BUFFER $SPEED
final_img_cnt=`ls output/| wc -l`

if [[ $final_img_cnt -eq 0 ]]
then
	echo "No files left for upload"
	exit
fi

if [ $TEST = true ]
then
	echo "Only a test - no upload to Mapillary or OpenStreetCam"
	exit 0
fi

#Upload to Mapillary

if [ ${SERVICE} == "BOTH" ] || [ ${SERVICE} == "MAPILLARY" ]
then
	mapillary_tools process_and_upload $RERUNOPT --import_path /Volumes/SD256/ROAV/foo/output/ --user_name ${mapillary_user_name}
	if [[ $? -ne 0 ]] ; then
		echo "Mapillary process and upload failed"
		exit 1
	else
		echo "Maillary Upload Success"
	fi
	#Remove Mapillary Image Description tag
	exiftool -ImageDescription=  output/
fi

#Upload to OpenStreetCam

if [ ${SERVICE} == "BOTH" ] || [ ${SERVICE} == "OSC" ]
then
	python3 ~/Development/upload-scripts/osc_tools.py upload -p output/
	if [[ $? -ne 0 ]] ; then
		echo "OpenStreetCam upload failed"
		exit 1
	else
		echo "OpenStreetCam Upload Success"
	fi
fi
