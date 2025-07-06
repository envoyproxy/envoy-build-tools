#!/usr/bin/env bash

set -e -o pipefail

usermod -u "${BUILD_UID}" envoybuild
chown envoybuild:envoybuild /home/envoybuild
chown envoybuild:envoybuild /home/envoybuild/.cache

if [[ -f /entrypoint-extra.sh ]]; then
    . /entrypoint-extra.sh
fi
exec gosu envoybuild "$@"
if [[ -f /cleanup.sh ]]; then
    . /cleanup.sh
fi
