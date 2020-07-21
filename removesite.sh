#!/bin/bash
###################################################################
# removesite.sh domain 
#
# Disables site
# Removes apache configuration file
# Removes site directory and files
# Removes any Let's Encrypt certificates
#
# NOTE: Does not delte WordPress database
###################################################################

checkForError() {
################################################################
# checks $? (return code status of last command)
#
# OUTPUT: On error, writes "$successMsg (failure)" to stdout and 
#                   does exit 1
#         On success, writes $successMsg to stdout and
#                     function returns
################################################################
  if [ $? -eq 0 ]
  then
    echo $successMsg
  else
    echo "$successMsg (failure)"
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

# Check for correct number of arguments and setup variables
if [ $# -eq 1 ]
then
  domain=$1
else
  echo "Invalid Number of Arguments ($#)"
  echo $USAGE
  exit 1
fi

if [[ "$domain" =~ ^www[.] ]]
then
  echo "Domain should be a bare domain -- no www."
  echo $USAGE
  exit 1
fi

# get user confirmation before removing site
echo "Running this script will remove Apache configuration file, website files and folders, and SSL certificate (if it exists) for $domain."
read -p "Enter DELETE (all caps) to continue: " continueResponse
if [ "$continueResponse" != "DELETE" ]
then
  exit 1
fi

# set up variables
siteDir=/var/www/$domain
confDir=/etc/apache2/sites-available
letsEncryptDir=/etc/letsencrypt

echo "Removing website: $domain"

# disabling site
successMsg="...disabled site"
a2dissite $domain >/dev/null 2>&1
checkForError

# reload apache service to update configuration
successMsg="...Reloaded apache web server"
service apache2 reload
checkForError

# remove configuration file
successMsg="...Removed configuration file"
rm -f $confDir/$domain.conf
checkForError

# remove site files
successMsg="...deleted $siteDir"
rm -rf $siteDir
checkForError

# remove Let's Encrypt certificate files
successMsg="...removed https certificates (if they existed)"
rm -rf $letsEncryptDir/live/$domain
rm -rf $letsEncryptDir/archive/$domain
rm -rf $letsEncryptDir/renewal/$domain.conf
checkForError

echo "Site disabled and removed."
echo "If necessary, please complete the following tasks manually:"
echo "- Drop WordPress database and user"
