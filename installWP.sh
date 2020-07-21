#!/bin/bash
###################################################################
# installWP.sh domain
#
# Installs wordpress for a given domain hosted on this server
#
# INPUT: $1 = fully qualified domain name for the new website 
#             (i.e. app.company.com)
#
# OUTPUT FILE LOCATIONS:
#   /var/www/$1/public_html = root directory for website
###################################################################

checkForError() {
################################################################
# checks $? (return code status of last command)
#
# OUTPUT: On error, writes "failure" to stdout and does exit 1
#         On success, writes $successMsg to stodout and
#                     function returns
################################################################
  if [ $? -eq 0 ]
  then
    echo $successMsg
  else
    echo "failure"
    exit 1
  fi
}

USAGE="Usage: $0 domain"

# Check that script is running as root (i.e. with sudo)
if [ "$EUID" -ne 0 ]
then 
  echo "Please run as root"
  echo $USAGE
  exit 1
fi

# Check for correct number of arguments
if [ $# -ne 1 ]
then
  echo "Number of Arguments = $#"
  echo $USAGE
  exit 1
fi

# setup variables
domain=$1
siteDir=/var/www/$domain/public_html
runDir=`pwd`

echo "INSTALLING WORDPRESS"

successMsg="switched to $siteDir"
cd $siteDir
checkForError

echo "Downloading WordPress"
successMsg="...downloaded WordPress"
wget -q https://wordpress.org/latest.tar.gz
checkForError

echo "Extracting WordPress"
successMsg="...extracted WordPress"
tar -xzvf latest.tar.gz >/dev/null 2>&1
checkForError
successMsg="...moved files"
mv wordpress/* ./
checkForError
successMsg="...removing wordpress download"
rm latest.tar.gz
checkForError
successMsg="...removing wordpress directory"
rmdir wordpress
checkForError


echo "Creating database"
DBName=`echo $domain | sed "s/\./_/g"`
DBUser=`echo $domain | sed "s/\./_/g"`
DBPassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1`
authKey=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
secureAuthKey=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
loggedInKey=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
nonCEKey=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
authSalt=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
secureAuthSalt=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
loggedInSalt=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
nonCESalt=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

successMsg="...created database"
cat $runDir/installWP.sql | sed "s/~~~DBName~~~/$DBName/g" | sed "s/~~~DBUser~~~/$DBUser/g" | sed "s/~~~DBPassword~~~/$DBPassword/g" | mysql 
checkForError


echo "Configuring WordPress"
successMsg="...created awk script"
cat $runDir/installWP.awk | sed "s/~~~DBName~~~/$DBName/g" | sed "s/~~~DBUser~~~/$DBUser/g" | sed "s/~~~DBPassword~~~/$DBPassword/g" | sed "s/~~~authKey~~~/$authKey/g" | sed "s/~~~secureAuthKey~~~/$secureAuthKey/g" | sed "s/~~~loggedInKey~~~/$loggedInKey/g" | sed "s/~~~nonCEKey~~~/$nonCEKey/g" | sed "s/~~~authSalt~~~/$authSalt/g" | sed "s/~~~secureAuthSalt~~~/$secureAuthSalt/g" | sed "s/~~~loggedInSalt~~~/$loggedInSalt/g" | sed "s/~~~nonCESalt~~~/$nonCESalt/g" >$runDir/installWP.awk.tmp
checkForError

successMsg="...created wp-config.php"
awk -f $runDir/installWP.awk.tmp <wp-config-sample.php >wp-config.php
checkForError

successMsg="...added plugins"
mkdir -p $siteDir/wp-content/plugins
cp -R $runDir/wpplugins/* $siteDir/wp-content/plugins/
checkForError

successMsg="...removed temporary awk program"
rm $runDir/installWP.awk.tmp
checkForError

rm -f $siteDir/index.html >/dev/null 2>&1
rm -f $siteDir/index.htm >/dev/null 2>&1

# set ownership and permissions for site
successMsg="Made www-data the site owner"
chown -R www-data $siteDir
checkForError

successMsg="Made webdev the site group"
chgrp -R webdev $siteDir
checkForError

successMsg="Set site permissions"
chmod -R u=rwx,g=rwx,o= $siteDir
checkForError

