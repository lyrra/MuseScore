#!/bin/bash

# do not build mac for PR
if [ "${TRAVIS_PULL_REQUEST}" != "false" ]; then
  exit 0
fi

wget -nv http://utils.musescore.org.s3.amazonaws.com/qt5121_mac.zip
mkdir -p $QT_MACOS
unzip -qq qt5121_mac.zip -d $QT_MACOS
rm qt5121_mac.zip
