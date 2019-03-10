BEGIN{FS=","
       i = 1
       printf "sourcefile,datetimeoriginal,gpslatitude,gpslongitude,gpsaltitude,gpsspeed,gpsimgdirection,gpslatituderef,gpslongituderef,gpsaltituderef\n"
	}
	{ 
	len = length(FILENAME)
	if( len == 25)
		f = substr(FILENAME,18,3)
	else
		f = substr(FILENAME,18,4)

	  datetime = substr($1,1,4) ":" substr($1,5,2) ":" + substr($1,7,2) " " substr($1,10,8)
	  lat = $2
	  long = $3 
	  ele = $6
	  speed = $7
	  head = $8
	  latref="N"
	  longref="W"
	  altituderef="above"
	  printf("jpeg/%s_%03d.jpeg,%s,%s,%s,%s,%s,%s mph,%s,%s,%s\n"), f,i,datetime,lat,long,ele, head, speed,latref,longref,altituderef
	  i = i + 1
	}
