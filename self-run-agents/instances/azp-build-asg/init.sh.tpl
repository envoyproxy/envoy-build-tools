#!/usr/bin/env bash

# Hostname shows in AZP side, use Instance ID Rather than a public ip.
instance_id=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
echo "$instance_id" > /etc/hostname
echo "127.0.1.1 $instance_id" >> /etc/hosts
hostname "$instance_id"

mkdir -p /run/aws-metadata/
echo -n "${asg_name}" > /run/aws-metadata/asg-name
/usr/local/bin/aws-metadata-refresh.sh

# Configure Azure Pipelines Agent, this has to be done at runtime since
# it will show up in the UI once we configure.
sudo -u azure-pipelines /bin/bash -c 'cd /srv/azure-pipelines && ./config.sh --unattended --acceptteeeula --url https://dev.azure.com/cncf/ --pool ${azp_pool_name} --token ${azp_token}'
sudo -u azure-pipelines mkdir /srv/azure-pipelines/_work

# Block Azure Pipelines from Making Requests to Local Instance User Data.
iptables -A OUTPUT -d 169.254.169.254 -m owner ! --uid-owner root -j DROP
iptables -A OUTPUT -s 169.254.169.254 -m owner ! --uid-owner root -j DROP
iptables -I DOCKER-USER -s 169.254.169.254 -j DROP
iptables -I DOCKER-USER -d 169.254.169.254 -j DROP

# Start AZP Agent.
function terminate {
    # Terminate instances in 1 min
    shutdown -h +1
}
trap terminate EXIT

# This is a hook to be run when a job starts
(inotifywait /srv/azure-pipelines/_work -e CREATE && /usr/local/bin/detach-self.sh || true) &

sudo -u azure-pipelines /bin/bash -c 'cd /srv/azure-pipelines && ./run.sh --once'
