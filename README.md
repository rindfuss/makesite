# bash scripts for website creation and maintenance

## Background
I found myself wanting the ability quickly to spin up and sometimes destroy websites for development purposes and created these scripts to automate much of the tedious work.

## Features
- Create and activate Apache website for a given domain including Apache config file and basic website directory structure
- Clone git repository to new website
- Install and configure WordPress for a new website including loading a set of standard plugins
- Generate and install Let's Encrypt SSL certificate for new website and redirect traffic from http:// to https:// while still allowing Let's Encrypt's automated certificate renewal to function over http://
- Manually obtain a Let's Encrypt SSL certificate for a domain when one wasn't requested automatically to be obtained during website creation.
- Manually renew SSL certificate for a domain if automated renewal fails.
- Remove a website including deactivating it, removing Apache config file, removing website directories, and removing Let's Encrypt SSL certificates.

## Prerequisites
- These scripts are designed to work with the LAMP (Linux, Apache, MySQL, PHP) stack and have been tested on Debian.
- If cloning a git repository using ssh, root's public key will need to be accepted by your git repo provider, because since the makesite.sh runs under sudo, it will provide root's public key rather than the public key of the user that issued the sudo command.
- SSL functions require Let's Encrypt's certbot to be installed.
- When creating an SSL site make sure your domain's DNS A record has already been set up to point to your server; otherwise, Let's Encrypt will not be able to validate that you control the site.

> Written with [StackEdit](https://stackedit.io/).
