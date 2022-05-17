#!/bin/bash

set -e

echo "Disk space before package removal"
df -h

dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -rn

# Temporary script to remove tools from Azure pipelines agent to create more disk space room.
PURGE_PACKAGES=(
    "adoptopenjdk-*"
    "ant"
    azure-cli
    "dotnet-*"
    firefox
    "ghc-*"
    google-chrome-stable
    hhvm
    libgl1
    "libllvm*"
    "nginx*"
    "mongodb*"
    "mono*"
    "mssql*"
    "mysql-*"
    "podman"
    "powershell"
    "php*"
    "temurin-*-jdk")

sudo apt-get update -y || true
sudo apt-get purge -y --no-upgrade "${PURGE_PACKAGES[@]}"

echo "Disk space after package removal"
df -h
