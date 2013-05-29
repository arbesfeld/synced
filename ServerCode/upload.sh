find . -not -path '*/beattracker*' -a -not -name '*DS_Store' -exec scp -i ../arbesfeld.pem {} ec2-user@54.214.244.4:/opt/app/current/ \;

