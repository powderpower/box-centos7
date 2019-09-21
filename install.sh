#!/bin/bash

domain=virtual-example.com
docRoot=/var/www
binPath=/bin
hostDir=/vagrant
httpdPath=/etc/httpd
php=php
publicPath="public"
commonPath=$hostDir/common
scriptPath=$hostDir/scripts
vhGenerator=generate-vhost
vhRemover=remove-vhost
serverRestarter=server-restart
installerRepos=/etc/yum.repos.d/

sudo yum update -y

echo "##### Generating common filesystems #####"
sudo mkdir $docRoot
sudo mkdir -p $hostDir/html
sudo mkdir -p $hostDir/log
sudo ln -s $hostDir/html $docRoot/html
sudo ln -s $hostDir/log $docRoot/log
sudo cp -rf $scriptPath/* $binPath
sudo cp -rf $commonPath/repo/* $installerRepos

# common utils
sudo yum install -y epel-release htop nano dos2unix net-tools

# scripts init
sudo dos2unix $binPath/$vhGenerator
sudo dos2unix $scriptPath/$vhRemover
sudo dos2unix $binPath/$serverRestarter
sudo chmod u+x $binPath/$vhGenerator
sudo chmod u+x $binPath/$serverRestarter
sudo chmod u+x $binPath/$serverRestarter

# apache
sudo yum update -y
sudo yum install -y httpd mod_fcgid
sudo cp -rf $commonPath/conf/httpd.conf $httpdPath/conf/httpd.conf
sudo mkdir $httpdPath/sites-available
sudo mkdir $httpdPath/sites-enabled

# template
echo "##### Generating sites filesystems #####"
sudo $vhGenerator $domain 80 $publicPath

# php
sudo rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum -y update
sudo yum-config-manager --enable remi-php71
sudo yum -y install $php
php -v
# extensions
sudo yum --enablerepo=remi install -y $php-opcache $php-mcrypt \
    $php-fpm $php-intl $php-gmp $php-imap $php-ldap $php-mbstring \
    $php-mysqli $php-pdo_odbc $php-pdo_pgsql $php-redis $php-redis \
    $php-soap $php-tidy $php-xmlrpc $php-zip
# imagick
sudo yum install -y gcc php-devel php-pear ImageMagick ImageMagick-devel
sudo pecl install imagick
sudo cp -rf $commonPath/ini/imagick.ini /etc/php.d/

# redis
sudo yum install -y redis
sudo systemctl start redis

# mariaDB
sudo yum install -y MariaDB-server
sudo systemctl start mariadb

# fast-cgi
sudo systemctl start php-fpm
sudo systemctl enable php-fpm
sudo cp -rf $commonPath/conf/www.conf /etc/php-fpm.d/
sudo $serverRestarter

# autoload
sudo systemctl enable httpd
sudo systemctl enable redis