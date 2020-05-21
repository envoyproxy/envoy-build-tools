#!/bin/bash

set -e

echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

ARCH=$(dpkg --print-architecture)

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates gnupg-agent software-properties-common wget

wget -q -O - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key adv --list-public-keys --with-fingerprint --with-colons 0EBFCD88 2>/dev/null | grep 'fpr' | head -n1 | grep '9DC858229FC7DD38854AE2D88D81803C0EBFCD88'
sudo add-apt-repository -y "deb [arch=${ARCH}] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-add-repository -y ppa:git-core/ppa

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io libunwind8 libcurl3 git awscli jq

sudo mkdir -p /etc/docker
echo '{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64"
}' | sudo tee /etc/docker/daemon.json

sudo systemctl enable docker
sudo systemctl start docker

sudo useradd -ms /bin/bash -G docker azure-pipelines
sudo mkdir -p /srv/azure-pipelines
sudo chown -R azure-pipelines:azure-pipelines /srv/azure-pipelines/

if [[ "${ARCH}" == "amd64" ]]; then
  wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb
  sudo apt-get update
  sudo apt-get install -y dotnet-runtime-3.1

  ARCH=x64
fi
AGENT_VERSION=2.168.2
AGENT_FILE=vsts-agent-linux-${ARCH}-2.168.2

sudo -u azure-pipelines /bin/bash -c "wget -q -O - https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/${AGENT_FILE}.tar.gz | tar zx -C /srv/azure-pipelines"
sudo -u azure-pipelines /bin/bash -c 'mkdir -p /home/azure-pipelines/.ssh && touch /home/azure-pipelines/.ssh/known_hosts'
sudo -u azure-pipelines /bin/bash -c 'ssh-keyscan github.com | tee /home/azure-pipelines/.ssh/known_hosts'
sudo -u azure-pipelines /bin/bash -c 'ssh-keygen -l -f /home/azure-pipelines/.ssh/known_hosts | grep github.com | grep "SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8"'

sudo mv /home/ubuntu/set-instance-protection.sh /usr/local/bin/set-instance-protection.sh
sudo chown azure-pipelines:azure-pipelines /usr/local/bin/set-instance-protection.sh
sudo chmod 0755 /usr/local/bin/set-instance-protection.sh
