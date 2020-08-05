#!/bin/bash

chown envoydev /docs
rm -rf /docs/*

exec gosu envoydev "${@}"
