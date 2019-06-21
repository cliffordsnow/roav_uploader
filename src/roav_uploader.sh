#!/bin/bash

usage() {
	echo "Usage: $0 [-h help][-r rerun mapillary ][-s mapillary|osc] [-c crop] [-b buffer] [-t test only]  video_file" 1>&2
}

exit_abnormal() {
	usage
	exit 1
}

get_image_size() {
	image_size=`exiftool "${dir}/${video}.MP4" | gawk -F ":" '/Image Size/ {print $2}'`
	echo $image_size
}
full_path() {
	f_path=$( cd $(dirname $filename); pwd -P)
}

get_dir(){
	dir=$(dirname $filename)
}

source ~/roav.config
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
else
	filename=$1
	if ! [[ $filename =~ "^\/.*MP4" ]]
	then
		full_path #return f_path
	fi
	get_dir  #returns dir
fi


input_file=`echo $1|sed -e 's/.MP4//'`
video=`basename -s .MP4 $1`

if ! [ -d "$WORKINGDIR" ]
then
	mkdir -p "$WORKINGDIR"
fi

if ! [ -d "${WORKINGDIR}/jpeg" ]
then
	mkdir "${WORKINGDIR}/jpeg"
fi

if ! [ -d "${WORKINGDIR}/output" ]
then
	mkdir "${WORKINGDIR}/output"
fi

#this is for testing purposes
#change to mv for production version



cd "$WORKINGDIR"

rm jpeg/*
rm output/*
rm -r output/.mapillary/*
rm *.csv


video_no=`echo $video|sed -e 's/^20.._...._......_//'`

#Creation of the .csv file for geocoding images
gawk -f "${TOOLDIR}/info2csv.awk" ${dir}/${video}.info > ${video_no}.csv

frames=`cat ${dir}/${video}.info|wc -l`

#get image size
get_image_size

if [ $CROP ]; then
	crop=`echo $CROP | tr "[xX]" ":"`
	echo "Cropping ${image_size} image to ${crop}"
	CROPCLAUSE="-vf crop=${crop} "
else
	echo "Not Cropping ${image_size} image"
fi

ffmpeg -i ${dir}/${video}.MP4 -ss 00:00:01 -t ${frames} -r 1 $CROPCLAUSE -qscale:v $JPEGQUALITY jpeg/${video_no}_%03d.jpeg

# Now we need to add the geotags to each image.
# exiftool makes it easy to geotag a folder of images. The key is the creation of the .csv file which occured earlier.
# first add make and model

exiftool -make='Anker' -model='ROAV Dashcam C1' jpeg/

exiftool -DateTimeOriginal -GPSLatitude -GPSLongitude -GPSAltitude -GPSspeed -GPSimagedirection -GPSLatitudeRef -GPSLongitudeRef -GPSAltitudeRef -csv=${video_no}.csv -o output/ jpeg/

#remove images near home
#need to create a optarg for boundary size

echo "Pruning out files within buffer distance ${BUFFER}km"
python "${TOOLDIR}/distance.py" ${video_no}.csv $HOMELAT $HOMELON $BUFFER
final_img_cnt=`ls output/| wc -l`

if [[ $final_img_cnt -eq 0 ]]
then
	echo "No files left for upload"
	exit
fi

if [ "$TEST" = true ]
then
	echo "Only a test - no upload to Mapillary or OpenStreetCam"
	exit 0
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

