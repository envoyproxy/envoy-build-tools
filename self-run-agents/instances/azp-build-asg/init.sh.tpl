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

# Start AZP Agent.
(cd /srv/azure-pipelines && ./svc.sh install azure-pipelines)
systemctl daemon-reload
systemctl enable azp-agent.service
systemctl start azp-agent.service