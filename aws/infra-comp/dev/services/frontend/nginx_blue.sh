#!/bin/bash
set -euf -o pipefail
exec 1> >(logger -s -t $(basename $0)) 2>&1
sudo apt-get update
sudo apt-get -y install nginx
echo '<html><head><title>PyHowTo Server</title></head>
<body style="background-color:#2FAABD">
<p style="text-align: center;">
<span style="color:#FFFFFF;">
<span style="font-size:28px;">PyHowTo Blue Team on AWS cluster "${cluster-name}"</span>
</span>
<p>DB Address: ${database-address}</p>
<p>DB port: ${database-port}</p>
<p><b>Note:</b> The DB is not publicly accessible...</p>
<hr>
<p><a href="https://pyhowto.tech">Visit the project page</a></p>
</p></body></html>' | sudo tee /var/www/html/index.html
sudo systemctl enable nginx
# sudo systemctl status nginx
