#!/bin/bash

set -e

./build_container_ubuntu.sh

#############
# Install JDK
#############

# Add Azul's public key
apt-key adv \
    --keyserver hkp://keyserver.ubuntu.com:80 \
    --recv-keys 0xB1998361219BD9C9

# Download and install the package that adds
# the Azul APT repository to the list of sources
curl -O https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb

# Install the Java 8 JDK
apt-get install -y ./zulu-repo_1.0.0-3_all.deb
apt-get update -y
apt-get install -y zulu8-jdk
rm ./zulu-repo_1.0.0-3_all.deb

#######################
# Install Android tools
#######################

mkdir -p "$ANDROID_HOME"
cd "$ANDROID_SDK_INSTALL_TARGET"

cmdline_file="commandlinetools-linux-7583922_latest.zip"
curl -OL "https://dl.google.com/android/repository/$cmdline_file"
unzip "$cmdline_file"
mkdir -p sdk/cmdline-tools/latest
mv cmdline-tools/* sdk/cmdline-tools/latest

sdkmanager=$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager
echo "y" | $sdkmanager --install "ndk;$ANDROID_NDK_VERSION"
$sdkmanager --install "platforms;android-30"
$sdkmanager --install "build-tools;30.0.2"

##########
# Clean up
##########

apt-get clean
