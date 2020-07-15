#!/usr/bin/env bash

set -e

function terminate {
    # Terminate instances in 1 min
    shutdown -h +1
}
trap terminate EXIT

# Hostname shows in AZP side, use Instance ID Rather than a public ip.
instance_id=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
echo "127.0.1.1 $instance_id" >> /etc/hosts
hostnamectl set-hostname "$instance_id"

azp_token=$(aws s3 cp s3://cncf-envoy-token/azp_token -)

export AWS_DEFAULT_REGION=us-east-1
aws ec2 replace-iam-instance-profile-association --iam-instance-profile Arn=${instance_profile_arn} \
  --association-id $(aws ec2 describe-iam-instance-profile-associations --filter=Name=instance-id,Values=$instance_id | jq -r '.IamInstanceProfileAssociations[0].AssociationId')

# Configure Azure Pipelines Agent, this has to be done at runtime since
# it will show up in the UI once we configure.
sudo -u azure-pipelines /bin/bash -c "cd /srv/azure-pipelines && ./config.sh --unattended --acceptteeeula --url https://dev.azure.com/cncf/ --pool ${azp_pool_name} --token $azp_token"
sudo -u azure-pipelines mkdir /srv/azure-pipelines/_work

# Clear credential cache and verify we're in right role before starting agent
unset azp_token
rm -rf ~/.aws
aws sts get-caller-identity | jq -r '.Arn' | grep -o "/${role_name}/"

# Setup bazel remote cache S3 proxy
echo "
[Unit]
Description=Bazel Remote Cache Service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=bazel-remote
ExecStart=/usr/local/bin/bazel-remote --s3.endpoint s3.us-east-1.amazonaws.com --s3.bucket ${bazel_cache_bucket} --s3.prefix ${cache_prefix} --s3.iam_role_endpoint http://169.254.169.254 --max_size 30 --dir /dev/shm/bazel-remote-cache

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/bazel-remote.service

systemctl daemon-reload
systemctl enable bazel-remote
systemctl start bazel-remote

# This is a hook to be run when a job starts
(inotifywait /srv/azure-pipelines/_work -e CREATE && aws autoscaling detach-instances --instance-ids $instance_id --auto-scaling-group-name ${asg_name} --no-should-decrement-desired-capacity || true) &

# Start AZP Agent.
sudo -u azure-pipelines /bin/bash -c 'cd /srv/azure-pipelines && ./run.sh --once'
