import requests

URL = 'http://www.synced-app.com/airshare-upload.php'
filename = 'music.mp3'
payload = {
	"id": "000000",
	"sessionid": "999999"
}

session = requests.session()
try:
	f = open(filename, 'rb')
except IOError:
	print "Could not open file!"
	
r = requests.post(url = URL, files = {'musicfile' : f}, data = payload)
print r.status_code
print r.headers
print r.text