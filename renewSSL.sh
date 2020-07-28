#!/bin/bash
###################################################################
# renewSSL.sh 
#
# Prompts user to renew an SSL certificate 
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

RED='\033[0;31m'
YELLOW='\033[1;33m'
NOCOLOR='\033[0m'

siteDir=/var/www/$domain

echo -e "${YELLOW}###############################################################"
echo             "## When prompted for how you would like to authenticate,"
echo -e          "##     ${RED}select option 3, Place files in webroot directory (webroot)"
echo -e "${YELLOW}##"
echo -e          "## When prompted for the webroot, enter"
echo -e          "##     ${NOCOLOR}/var/www/$domain/public_html"
echo -e "${YELLOW}###############################################################${NOCOLOR}"
successMsg="Renewed SSL certificate for $domain"
certbot certonly -d $domain
checkForError

