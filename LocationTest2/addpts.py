from sys import argv

kmlfile = argv[1]
datafile = argv[2]

kml = file(kmlfile, 'r').readlines()
kml = kml[:-1]
kml[-1] = '</Placemark>'

for i in file(datafile, 'r').readlines():
    if ',' in i:
        i = i.split(',')
        s = '<Placemark><name>%.0f</name><Point><coordinates>%s, %s, 0.</coordinates></Point></Placemark>\n' % (float(i[2]) * 1000, i[1], i[0])
        kml += [s]

for i in kml:
    print i.strip()

print '</Document></kml>'
