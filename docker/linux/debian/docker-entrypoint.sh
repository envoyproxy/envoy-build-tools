#!/usr/bin/env bash

set -e

DOCKER_SOCK="/var/run/docker.sock"
if [[ ! -S "$DOCKER_SOCK" ]]; then
    echo "ERROR: Docker socket required but not found at $DOCKER_SOCK"
    exit 1
fi
DOCKER_GID=$(stat -c '%g' $DOCKER_SOCK)
DOCKER_GROUP=$(stat -c '%G' $DOCKER_SOCK)
echo "Docker socket found with GID: $DOCKER_GID (group: $DOCKER_GROUP)"
EXISTING_GROUP=$(getent group $DOCKER_GID | cut -d: -f1)

mkdir -p /home/envoybuild/.docker
usermod -u "${BUILD_UID}" envoybuild
chown envoybuild:envoybuild /home/envoybuild
chown envoybuild:envoybuild /home/envoybuild/.cache
chown envoybuild:envoybuild /home/envoybuild/.docker

if [ -z "$EXISTING_GROUP" ]; then
    echo "Creating docker group with GID $DOCKER_GID"
    groupadd -g $DOCKER_GID docker
    DOCKER_GROUP="docker"
else
    echo "Using existing group: $EXISTING_GROUP"
    DOCKER_GROUP=$EXISTING_GROUP
fi
echo "Adding user envoybuild to group $DOCKER_GROUP" >&2
usermod -aG $DOCKER_GROUP envoybuild

if [[ -f /entrypoint-extra.sh ]]; then
    . /entrypoint-extra.sh
fi
exec gosu envoybuild "$@"
if [[ -f /cleanup.sh ]]; then
    . /cleanup.sh
fi
