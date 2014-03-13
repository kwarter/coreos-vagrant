#!/bin/sh
ETCD_DISCOVERY_URL="{{ etcd_discovery_url.stdout }}"
START_FLEET=1
SERVICE_NAME=docker-base

# setup 3 docker-base.service files
for i in 1 2 3
do cat > /media/state/units/${SERVICE_NAME}.${i}.service <<'EOF'
[Unit]
Description=docker-base
After=docker.service
Requires=docker.service

[Service]
ExecStart=/bin/bash -c '/usr/bin/docker start -a tony-container || /usr/bin/docker run -p 40022:22 -p 8081:8081 --expose=[22,8081] --name=tony-container monstaloc/docker-base /usr/sbin/sshd -D'
ExecStop=/usr/bin/docker stop tony-container

[X-Fleet]
X-Conflicts=docker-base.*.service
EOF
done

# start 3 docker-base services
for i in 1 2 3; do fleetctl start /media/state/units/${SERVICE_NAME}.${i}.service; done