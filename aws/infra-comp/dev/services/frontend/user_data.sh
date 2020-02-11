#!/bin/bash
set -euf -o pipefail
exec 1> >(logger -s -t $(basename $0)) 2>&1

cat > index.html <<-EOF
<h1>Hello on "${cluster-name}" site</h1>
<p>DB Address: ${database-address}</p>
<p>DB port: ${database-port}</p>
<p>Note: The DB is not publicly accessible...</p>
<hr>
<p><a href="https://pyhowto.tech">Visit the project page</a></p>
EOF

nohup busybox httpd -f -p "${server-port}" &
