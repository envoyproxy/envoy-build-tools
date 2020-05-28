#!/usr/bin/env bash

set -e

# Check Pre-Reqs, and that we're running on an AWS Instance Seemingly.
if ! hash aws >/dev/null 2>&1 ; then
  echo "Need the AWS Cli in order to set AWS Protection."
  exit 1
fi
if ! hash jq >/dev/null 2>&1 ; then
  echo "Need JQ in order to query credentials."
  exit 2
fi
if [[ ! -f "/sys/devices/virtual/dmi/id/board_asset_tag" ]]; then
  echo "Doesn't seem to be an AWS Instance: [/sys/devices/virtual/dmi/id/board_asset_tag] does not exist".
  exit 3
fi
instance_id=$(< /sys/devices/virtual/dmi/id/board_asset_tag)
if [[ ! "$instance_id" =~ ^i- ]]; then
  echo "Retrieved Instance ID: [$instance_id] does not start with [i-]"
  exit 4
fi

function ensureCredentials() {
  if [[ ! -f "/run/aws-protection-data/creds.json" ]] || [[ ! -f "/run/aws-protection-data/asg-name" ]] || [[ ! -f "/run/aws-protection-data/iid.json" ]]; then
    echo "Failed to find Credentials for AWS Instance."
    exit 5
  fi

  local readonly credentials_json=$(< /run/aws-protection-data/creds.json)
  local readonly iid_json=$(< /run/aws-protection-data/iid.json)
  local readonly asg_name=$(< /run/aws-protection-data/asg-name)
  local readonly aws_access_key=$(echo -n "$credentials_json" | jq -r .AccessKeyId)
  local readonly secret_access_key=$(echo -n "$credentials_json" | jq -r .SecretAccessKey)
  local readonly session_token=$(echo -n "$credentials_json" | jq -r .Token)
  local readonly expiration=$(echo -n "$credentials_json" | jq -r .Expiration)
  local readonly region=$(echo -n "$iid_json" | jq -r .region)

  echo "Fetched Cached Credentials, Expire At: [$expiration]"
  export AWS_ACCESS_KEY_ID="$aws_access_key"
  export AWS_SECRET_ACCESS_KEY="$secret_access_key"
  export AWS_SESSION_TOKEN="$session_token"
  export AWS_DEFAULT_REGION="$region"
  export CURRENT_ASG_NAME="$asg_name"
}

ensureCredentials
if [[ "$1" == "on" ]]; then
  aws autoscaling set-instance-protection --instance-ids "$instance_id" --auto-scaling-group-name "$CURRENT_ASG_NAME" --protected-from-scale-in
else
  aws autoscaling set-instance-protection --instance-ids "$instance_id" --auto-scaling-group-name "$CURRENT_ASG_NAME" --no-protected-from-scale-in
fi