from sys import argv

# generate and then go here to get a map: http://www.freemaptools.com/radius-around-point.htm

fname = argv[1]
data = file(fname, 'r').readlines()

for i in range(len(data)):
    if 'DATA POINT' in data[i]:
        latitude = data[i + 1].split(' ')[1].strip()
        longitude = data[i + 2].split(' ')[1].strip()
        radius = data[i + 4].split(' ')[2].strip()
        print str(latitude) + ','+ str(longitude) + ',' + str(float(radius) / 1000.0)
