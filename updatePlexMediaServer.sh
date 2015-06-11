#!/bin/bash

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

echo 'Fetching current version name...'
text=`curl -s https://plex.tv/downloads | grep ${DIST}${BIT}`
regex='(<a\ +href=\")([^\"]+)(\".*>)'
[[ $text =~ $regex ]]

file=`echo ${BASH_REMATCH[2]}`
echo $file
regex='(.*/)(plexmedia.*[deb|rpm])(.*)'
[[ $file =~ $regex ]]
filename=`echo ${BASH_REMATCH[2]}`
echo $filename

echo 'Fetching current file...'
wget -c $file

echo 'Installing new version...'
if [ ${DIST} == "Ubuntu" ]; then
  sudo dpkg -i $filename
else
  sudo yum -y install $filename
fi

echo 'Cleaning up...'
rm -f $filename
