#!/bin/bash
cookiePath='./plexcookies.txt'

echo "Plex Media Server Upgrade Utility"
echo

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

if [ `echo $* | grep -c -e "--plexpass"` -eq 1 ]; then
  # need to extract plexpass  version
  echo -n "Attempting to get Plexpass version information: "
  text=`curl -L -c $cookiePath -b $cookiePath --silent 'https://plex.tv/downloads?channel=plexpass' | grep ${DIST}${BIT}`
  if [ $? -eq 1 ]; then
    # FAILED LOGIN BY COOKIE. Ask for credentials and try again
    echo "NOT LOGGED IN"
    echo
    echo "Please enter your Plex.tv Login Credentials"
    echo "(THESE ARE NEVER STORED. ONLY LOGIN COOKIE SAVED)"
    
    echo -n "Username or email: "
    read userName
    echo -n "Password: "
    read -s userPassword
    echo

    authToken=`curl -L -c $cookiePath --silent 'https://plex.tv/users/sign_in' | grep authenticity_token`
    regex='<input\ +name=\"authenticity_token\"\ +type=\"hidden\"\ +value\"([^\"]*)\"'
    [[ $authToken =~ $regex ]]
    authToken=`echo ${BASH_REMATCH[1]}`

    echo -n "Attempting login: "
    curl -L -c $cookiePath -b $cookiePath --silent --data-urlencode user[login]=$userName --data-urlencode user[password]=$userPassword --data 'user[remember_me]=1' --data-urlencode authenticity_token=$authToken 'https://plex.tv/users/sign_in' >/dev/null

    text=`curl -L -c $cookiePath -b $cookiePath --silent 'https://plex.tv/downloads?channel=plexpass' | grep ${DIST}${BIT}`
    if [ $? -eq 1 ]; then
      echo "FAILED. ABORTING!"
      exit 1
    else
      echo "OK"
    fi
  else
    echo "OK"
  fi
else
  echo "Getting standard Plex version information: OK"
  text=`curl -s https://plex.tv/downloads | grep ${DIST}${BIT}`
fi

regex='(<a\ +href=\")([^\"]+)(\".*>)'
[[ $text =~ $regex ]]

file=`echo ${BASH_REMATCH[2]}`
regex='(.*/)(plexmedia.*[deb|rpm])(.*)'
[[ $file =~ $regex ]]
filename=`echo ${BASH_REMATCH[2]}`

regex='(plex-media-server/)([^\/]+)(.*)'
[[ $file =~ $regex ]]
newversion=`echo ${BASH_REMATCH[2]}`

INSTALLED_VERSION=`dpkg -l | grep plexmediaserver | awk '{ print $3; }'`
echo "Installed version: $INSTALLED_VERSION"
echo "New version:       $newversion"

if [ `echo $* | grep -c -e "--simulate"` -eq 1 ]; then
  exit 0
fi

if [ `echo $* | grep -c -e "\ -s\ *"` -eq 1 ]; then
  exit 0
fi

if [ $INSTALLED_VERSION == $newversion ]; then
  echo "Already have latest version."
  exit 1
fi
echo 'Fetching current file...'
#wget -c $file
sudo curl -# -o $filename $file

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
