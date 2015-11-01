#!/bin/bash

INSTALLED_VERSION=`dpkg -l | grep plexmediaserver | awk '{ print $3; }'`
echo "Installed version: $INSTALLED_VERSION"

ARCH=`uname -p`
if [ ${ARCH} == "i686" ]; then
  BIT="32"
elif [ ${ARCH} == "x86_64" ]; then
  BIT="64"
fi

cat /etc/*-release | grep -c Ubuntu >/dev/null 2>&1
if [ $? -eq 0 ]; then
  DIST="Ubuntu"
fi

cat /etc/*-release | grep -c Fedora >/dev/null 2>&1
if [ $? -eq 0 ]; then
  DIST="Fedora"
fi

cat /etc/*-release | grep -c CentOS >/dev/null 2>&1
if [ $? -eq 0 ]; then
  DIST="CentOS"
fi

text=`curl -s https://plex.tv/downloads | grep ${DIST}${BIT}`
regex='(<a\ +href=\")([^\"]+)(\".*>)'
[[ $text =~ $regex ]]

file=`echo ${BASH_REMATCH[2]}`
regex='(.*/)(plexmedia.*[deb|rpm])(.*)'
[[ $file =~ $regex ]]
filename=`echo ${BASH_REMATCH[2]}`

regex='(plex-media-server/)([^\/]+)(.*)'
[[ $file =~ $regex ]]
newversion=`echo ${BASH_REMATCH[2]}`
echo "New version:       $newversion"

if [ "$1" == "-s" ]; then
  exit 0
fi

if [ $INSTALLED_VERSION == $newversion ]; then
  echo "Already have latest version."
  exit 1
fi
echo 'Fetching current file...'
#wget -c $file
sudo curl -o $filename $file

if [ $? != 0 ]; then
  sudo rm -f $filename
  echo
  echo
  echo "ABORTED"
  exit 1
fi

echo 'Installing new version...'
if [ ${DIST} == "Ubuntu" ]; then
  sudo dpkg -i $filename
else
  sudo yum -y install $filename
fi

echo 'Cleaning up...'
sudo rm -f $filename
