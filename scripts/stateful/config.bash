#!/bin/bash

set -u
set -x

# this MUST be called AFTER consul and BEFORE nomad

# create the necessary configuration files/etc
echo "START: [${ASG_NAME}] instance [${ASG_INDEX}] ..."

echo "${ASG_INDEX}" > ${STATEFULID_FILE}

cat > /etc/systemd/system/locker.service <<EOT
[Unit]
Description=Consul Lock Grabber
Documentation=https://www.consul.io/docs/commands/lock.html
Wants=network-online.target consul.service
After=network.target network-online.target consul.service

[Service]
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/sbin/consul lock -monitor-retry=10 -verbose -timeout=5s -child-exit-code ${ASG_NAME}/instance-${ASG_INDEX} /bin/sleep infinity
Group=root
KillMode=process
KillSignal=SIGINT
LimitNOFILE=65536
LimitNPROC=infinity
Restart=on-failure
RestartSec=5
StartLimitBurst=3
StartLimitIntervalSec=10
TasksMax=infinity
Type=simple
User=root
WorkingDirectory=/

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl daemon-reload
sudo systemctl enable locker

# TODO: create the consul and nomad meta files

cat > /etc/consul/meta.hcl <<EOT
node_meta {
  "statefulid" = "${ASG_INDEX}"
}
EOT

cat > /etc/nomad/meta.hcl <<EOT
client {
  meta {
    "statefulid" = "${ASG_INDEX}"
  }
}
EOT

# XXX: is it dangerous to restart Consul under the lock handler ?!?
consul reload
sleep 5
sudo systemctl restart locker
sudo systemctl restart nomad

echo "DONE: [${ASG_NAME}] instance [${ASG_INDEX}] ..."
exit 0
