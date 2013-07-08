from sys import argv
from os import system

target = argv[1]

system('scp -i ../arbesfeld.pem %s ec2-user@54.214.244.4:/opt/app/current/%s' % (target, target))
