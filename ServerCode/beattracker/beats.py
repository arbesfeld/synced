from sys import argv
from os import system

import urllib2

url = "http://www.synced-app.com/airshare-download.php?id=%s&sessionid=%s" % (argv[1], argv[2])

tmp = argv[3]

file_name = "%s/beats.m4a" % tmp
u = urllib2.urlopen(url)
f = open(file_name, 'wb')
meta = u.info()
file_size = int(meta.getheaders("Content-Length")[0])
print "Downloading: %s Bytes: %s" % (file_name, file_size)

file_size_dl = 0
block_sz = 8192
while True:
    buffer = u.read(block_sz)
    if not buffer:
        break

    file_size_dl += len(buffer)
    f.write(buffer)
    status = r"%10d  [%3.2f%%]" % (file_size_dl, file_size_dl * 100. / file_size)
    status = status + chr(8)*(len(status)+1)
    print status,

f.close()

system("cd %s && faad beats.m4a" % tmp)
