BEGIN{FS=","
	last_pattern="_[0-9]+[A-Z]*\.info$"
       	i = 1
       	printf "sourcefile,datetimeoriginal,gpslatitude,gpslongitude,gpsaltitude,gpsspeed,gpsimgdirection,gpslatituderef,gpslongituderef,gpsaltituderef\n"
	}
	{ 
	len = length(FILENAME)
	where = match(FILENAME,last_pattern) + 1
	pattern_len = len - where - 4
	
	f = substr(FILENAME,where,pattern_len)

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
