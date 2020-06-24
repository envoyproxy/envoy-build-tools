#!/usr/bin/env bash

mkdir -p /run/aws-metadata/

role_name=$(wget -q -O - http://169.254.169.254/latest/meta-data/iam/security-credentials)
wget -q -O - "http://169.254.169.254/latest/meta-data/iam/security-credentials/$role_name" > /run/aws-metadata/creds.json
wget -q -O - http://169.254.169.254/latest/dynamic/instance-identity/document > /run/aws-metadata/iid.json

chmod 0400 /run/aws-metadata/creds.json
chmod 0400 /run/aws-metadata/iid.json
chmod 0400 /run/aws-metadata/asg-name
chown azure-pipelines:azure-pipelines /run/aws-metadata/creds.json
chown azure-pipelines:azure-pipelines /run/aws-metadata/iid.json
chown azure-pipelines:azure-pipelines /run/aws-metadata/asg-name
