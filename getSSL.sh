#!/bin/bash
###################################################################
# getSSL.sh domain 
#
# Obtains an SSL certificate for the given domain
#
# Useful when for example domain.com has already been set up and has
# an SSL certificate and now one is needed for www.domain.com
#
# Site must already be up and running (i.e. /var/www/domain/public_html) must exist 
# and be accessible via the web
#
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

# Check for correct number of arguments and setup variables
if [ $# -eq 1 ]
then 
  domain=$1
else
  echo "Invalid Number of Arguments ($#)"
  echo $USAGE
  exit 1
fi

siteDir=/var/www/$domain

echo "###############################################################"
echo "## When prompted for webroot, enter $siteDir/public_html" 
echo "###############################################################"
successMsg="Obtained SSL certificate for $domain"
certbot --authenticator webroot --installer apache
checkForError

