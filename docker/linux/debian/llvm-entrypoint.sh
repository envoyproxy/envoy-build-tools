#!/usr/bin/env bash

set -e -o pipefail

usermod -u "${USER_UID}" envoybuild &> /dev/null
chown envoybuild:envoybuild /home/envoybuild
export PATH="/opt/llvm/bin:${PATH}"
if [[ -e /home/envoybuild/.cache ]]; then
    chown envoybuild:envoybuild /home/envoybuild/.cache
fi
if [[ -f /entrypoint-extra.sh ]]; then
    . /entrypoint-extra.sh
fi
exec gosu envoybuild "$@"
if [[ -f /cleanup.sh ]]; then
    . /cleanup.sh
fi
