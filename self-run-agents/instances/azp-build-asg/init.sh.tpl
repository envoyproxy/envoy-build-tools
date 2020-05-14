#!/usr/bin/env bash

# Hostname shows in AZP side, use Instance ID Rather than a public ip.
instance_id=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
echo "$instance_id" > /etc/hostname
echo "127.0.1.1 $instance_id" >> /etc/hosts
hostname "$instance_id"

# Configure Azure Pipelines Agent, this has to be done at runtime since
# it will show up in the UI once we configure.
sudo -u azure-pipelines /bin/bash -c 'cd /srv/azure-pipelines && ./config.sh --unattended --acceptteeeula --url https://dev.azure.com/cncf/ --pool ${azp_pool_name} --token ${azp_token}'
# The Service Name Generated Contains hostname information, which we don't want. Rename.
sudo -u azure-pipelines /bin/bash -c 'cd /srv/azure-pipelines && sed -i "s,SVC_NAME=.*,SVC_NAME=azp-agent.service,g" ./svc.sh'

mkdir -p /usr/local/bin
echo '#!/usr/bin/env bash

mkdir -p /run/aws-protection-data/

role_name=$(wget -q -O - http://169.254.169.254/latest/meta-data/iam/security-credentials)
wget -q -O - "http://169.254.169.254/latest/meta-data/iam/security-credentials/$role_name" > /run/aws-protection-data/creds.json
wget -q -O - http://169.254.169.254/latest/dynamic/instance-identity/document > /run/aws-protection-data/iid.json
echo -n "${asg_name}" > /run/aws-protection-data/asg-name

chmod 0400 /run/aws-protection-data/creds.json
chmod 0400 /run/aws-protection-data/iid.json
chmod 0400 /run/aws-protection-data/asg-name
chown azure-pipelines:azure-pipelines /run/aws-protection-data/creds.json
chown azure-pipelines:azure-pipelines /run/aws-protection-data/iid.json
chown azure-pipelines:azure-pipelines /run/aws-protection-data/asg-name
' > /usr/local/bin/aws-metadata-refresh.sh
chmod +x /usr/local/bin/aws-metadata-refresh.sh

echo "[Unit]
Description=Refersh User Data Credentials for AZP
Wants=aws-metadata-refresh.timer

[Service]
ExecStart=/usr/local/bin/aws-metadata-refresh.sh
User=root

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/aws-metadata-refresh.service
echo "[Unit]
Description=Renew AWS Creds once every half hour
Requires=aws-metadata-refresh.service

[Timer]
Unit=aws-metadata-refresh.service
OnUnitInactiveSec=30m
RandomizedDelaySec=30m

[Install]
WantedBy=timers.target" > /lib/systemd/system/aws-metadata-refresh.timer
systemctl daemon-reload
systemctl enable aws-metadata-refresh.service aws-metadata-refresh.timer
systemctl start aws-metadata-refresh.service aws-metadata-refresh.timer
/usr/local/bin/aws-metadata-refresh.sh

# Block Azure Pipelines from Making Requests to Local Instance User Data.
iface=$(ls /sys/class/net/ | grep -v lo | grep -v docker0)
iptables -A OUTPUT -o "$iface" -s 169.254.169.254 -m owner --uid-owner azure-pipelines -j DROP
iptables -A OUTPUT -o "$iface" -d 169.254.169.254 -m owner --uid-owner azure-pipelines -j DROP
iptables -I DOCKER-USER -s 169.254.169.254 -j DROP
iptables -I DOCKER-USER -d 169.254.169.254 -j DROP

# Start AZP Agent.
(cd /srv/azure-pipelines && ./svc.sh install azure-pipelines)
systemctl daemon-reload
systemctl enable azp-agent.service
systemctl start azp-agent.service