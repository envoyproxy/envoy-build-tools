#!/usr/bin/env bash

set -e -o pipefail


if [[ -z "${USER_UID}" ]]; then
    echo "USER_UID must be set" >&2
fi

start_docker () {
    dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2376 > /var/log/docker/dockerd.log 2>&1 &
    while ! docker info >/dev/null 2>&1; do sleep 1; done
    DOCKER_SOCK="/var/run/docker.sock"
    if [[ ! -S "$DOCKER_SOCK" ]]; then
        echo "ERROR: Docker socket required but not found at $DOCKER_SOCK"
        exit 1
    fi
}

get_docker_info () {
    DOCKER_GID=$(stat -c '%g' $DOCKER_SOCK)
    DOCKER_GROUP=$(stat -c '%G' $DOCKER_SOCK)
    EXISTING_GROUP=$(getent group "$DOCKER_GID" | cut -d: -f1)
    echo "Docker socket found with GID: $DOCKER_GID (group: $DOCKER_GROUP)"
}

set_user_permissions () {
    mkdir -p /home/envoybuild/.docker
    usermod -u "${USER_UID}" envoybuild &> /dev/null
    chown envoybuild:envoybuild /home/envoybuild
    if [[ -e /home/envoybuild/.cache ]]; then
        chown envoybuild:envoybuild /home/envoybuild/.cache
    fi
    chown envoybuild:envoybuild /home/envoybuild/.docker
}

set_user_groups () {
    if [[ -z "$EXISTING_GROUP" ]]; then
        echo "Creating docker group with GID $DOCKER_GID"
        groupadd -g "$DOCKER_GID" docker
        DOCKER_GROUP="docker"
    else
        echo "Using existing group: $EXISTING_GROUP"
        DOCKER_GROUP=$EXISTING_GROUP
    fi
    echo "Adding user envoybuild to group $DOCKER_GROUP" >&2
    usermod -aG "$DOCKER_GROUP" envoybuild
}

start_docker
get_docker_info
set_user_permissions
set_user_groups

if [[ -f /entrypoint-extra.sh ]]; then
    # shellcheck disable=SC1091
    . /entrypoint-extra.sh
fi

exec gosu envoybuild "$@"
