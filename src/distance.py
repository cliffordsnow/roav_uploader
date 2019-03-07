import os
import sys
import csv
from math import radians, cos, sin, asin, sqrt

def distancekm(lon1, lat1, lon2, lat2):
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees)
    """
    # convert decimal degrees to radians 
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    # haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a)) 
    # Radius of earth in kilometers is 6371
    km = 6371* c
    return km


if(len(sys.argv) != 5):
    print("Error\nUsage: distance.py csv_file homelat homelon buffer")
    sys.exit(1)

homelat=float(sys.argv[2])
homelon=float(sys.argv[3])
buffer=float(sys.argv[4])

with open(sys.argv[1], 'r' ) as exif:
    csvReader = csv.reader(exif)
    next(csvReader)
    for row in csvReader:
        lat=float(row[2])
        lon=float(row[3])
        d=distancekm(lon,lat,homelon,homelat)
        if(d < buffer):
            cmd = "rm " + row[0].replace('jpeg','output',1)
            os.system(cmd)

