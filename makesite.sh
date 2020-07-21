#!/bin/bash
###################################################################
# makesite.sh domain ssl/nossl [gitRepoName]
#
# For a new website at the given domain, does the following:
# - Creates directory structure 
# - Creates conf file for apache
# - Enables the new site and reloads apache
# - optionally, populates the website by cloning a git repository
#
# PREREQUISITES:
# - Requires certbot for generating SSL certificates
#	
# INPUT: $1 = fully qualified domain name for the new website 
#             (i.e. test.rindfuss.org)
#	 $2 = ssl or nossl depending on whether or not an SSL-enabled
#             site is desired
#        $3 = git respository name (i.e. git@bitbucket.org:user/repo.git or 
#             https://github.com/rindfuss/democoinnative.git)
#
#             The repo should have a folder named public_html that contains
#             the website content.
#
#             The repo may have a folder named public_html/scripts for 
#	      scripts that should not be visible to web browsers but that
#             will be available to other scripts. For example, public_html
#             might contain index.php that includes code from 
#	      scripts/functions.php
#
#        makesite.conf = apache configuration file template for http
#                        Every instance of ~~~~~ in the file gets
#                        replaced by the domain of the new site
#        makesite-ssl.conf = apache configuration file template for https
#                            Every instance of ~~~~~ in the file gets
#                            replaced by the domain of the new site
#
# OUTPUT FILE LOCATIONS:
#   /var/www/_domain_/public_html         = document root for new website
#       - ownership of files will be set to www-data:webdev
#   ${APACHE_LOG_DIR}/_domain_.access.log = access log file
#   ${APACHE_LOG_DIR}/_domain_.error.log  = error log file
#   /etc/apache2/sites-available          = directory for domain.conf file
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

USAGE="Usage: $0 domain ssl/nossl [gitRepoToClone]"

# Check that script is running as root (i.e. with sudo)
if [ "$EUID" -ne 0 ]
then 
  echo "Please run as root"
  echo $USAGE
  exit 1
fi

# Check for correct number of arguments and setup variables
if [ $# -eq 3 ]
then 
  domain=$1
  sslflag=$2
  gitRepoName=$3
else
  if [ $# -eq 2 ]
  then
    domain=$1
    sslflag=$2
  else
    echo "Invalid Number of Arguments ($#)"
    echo $USAGE
    exit 1
  fi
fi

if [ "$sslflag" != "ssl" ] && [ "$sslflag" != "nossl" ]
then
  echo "Invalid ssl argument. It should be ssl or nossl"
  echo $USAGE
  exit 1
fi

if [[ "$domain" =~ ^www[.] ]] && [ "$sslflag" == "nossl" ]
then
  echo "Domain should be a bare domain -- no www."
  echo $USAGE
  exit 1
fi

if [[ "$domain" =~ ^www[.] ]] && [ "$sslflag" == "ssl" ]
then
  read -p "SSL-enabled sites are normally set up on bare domains (no www). Enter y to continue: " continueResponse
  if [ "$continueResponse" != "y" ]
  then
    exit 1
  fi
fi

siteDir=/var/www/$domain
confDir=/etc/apache2/sites-available
RED='\033[0;31m'
YELLOW='\033[1;33m'
NOCOLOR='\033[0m'

echo "creating website: $domain"

# create website directory structure
successMsg="created $siteDir"
mkdir -p $siteDir
checkForError

if [ $# -eq 2 ]
then
  successMsg="created $siteDir/public_html"
  mkdir $siteDir/public_html
  checkForError

  # create a sample index.html file
  successMsg="created $siteDir/public_html/index.html"
  echo "<html><head></head><body><h1>This is the website: $domain</h1></body></html>" >$siteDir/public_html/index.html
  checkForError

  successMsg="created $siteDir/public_html/scripts"
  mkdir $siteDir/public_html/scripts
  checkForError
fi

if [ $# -eq 3 ]
then
  echo "Creating website from git repository"
  successMsg="...cloned $gitRepoName"
  cd $siteDir
  git clone $gitRepoName ./
  checkForError
  cd - >/dev/null

  successMsg="...created .gitignore"
  echo '._*' >$siteDir/.gitignore
  echo '.DS_Store' >>$siteDir/.gitignore
  checkForError

  successMsg="...ensured public_html existed"
  mkdir -p $siteDir/public_html
  checkForError

fi

# set ownership and permissions for site
successMsg="Made www-data the site owner"
chown -R www-data $siteDir
checkForError

# create webdev group if it doesn't exist
if ! grep -q webdev /etc/group
then
  successMsg="Created webdev group"
  addgroup webdev
  checkForError
fi

successMsg="Made webdev the site group"
chgrp -R webdev $siteDir
checkForError

successMsg="Set site permissions"
chmod -R u=rx,g=rwx,o= $siteDir
checkForError

successMsg="Set site files to inheret group"
chmod g+s $siteDir
checkForError

# create website configuration file
successMsg="created $confDir/$domain.conf"
cat makesite.conf | sed "s/~~~~~/$domain/g" >$confDir/$domain.conf
checkForError

# enable new site. Must do it now so Lets Encrypt can place a file on it
# to establish ownership
successMsg="Enabled site: $domain"
a2ensite $domain >/dev/null 2>&1
checkForError

# reload apache service so that new site functions
successMsg="Reloaded apache web server"
service apache2 reload
checkForError

if [ "$sslflag" = "ssl" ]
then
  # get LetsEncrypt SSL certificate
  echo -e "${YELLOW}"
  echo "###############################################################"
  echo "## When prompted for webroot, enter $siteDir/public_html" 
  echo "##"
  echo "## When prompted to choose whether or not to redirect HTTP"
  echo -e "## traffic to HTTPS, ${RED}select option 1, No redirect"
  echo -e "${YELLOW}###############################################################${NOCOLOR}"
  successMsg="...Obtained SSL certificate"
  certbot --authenticator webroot --installer apache
  checkForError

  # Combine http and https configuration files into one
  successMsg="...Disabled site: http://$domain"
  a2dissite $domain >/dev/null 2>&1
  checkForError

  successMsg="...Disabled site: https://$domain"
  a2dissite $domain-le-ssl >/dev/null 2>&1
  checkForError

  # replace http configuration file with one that redirects to https
  successMsg="...updated $confDir/$domain.conf to redirect to https"
  cat makesite-ssl.conf | sed "s/~~~~~/$domain/g" >$confDir/$domain.conf
  checkForError

  successMsg="...Combined http and https configuration files"
  cat $confDir/$domain-le-ssl.conf >> $confDir/$domain.conf
  checkForError

  successMsg="...Removed standalone ssl configuration file"
  rm -f $confDir/$domain-le-ssl.conf
  checkForError

  successMsg="...Activated combined http / https site configuration"
  a2ensite $domain >/dev/null 2>&1
  checkForError

  successMsg="...Reloaded apache web server"
  service apache2 reload
  checkForError
fi

echo "If you're not in the webdev group, run the following:"
echo "  sudo usermod -a -G webdev yourusername"
echo "Then open a new shell with your primary group set to webdev for"
echo "the new shell only with:"
echo "  newgrp webdev"
echo "or change your primary group for every logon with:"
echo "  sudo usermod -g webdev yourusername"
echo "  note: you'll need to log out and back in or issue a newgrp command"
echo "        for this actually to take effect."
