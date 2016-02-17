#!/usr/bin/env bash

install_root=$(pwd)

yum clean all
yum -y update
yum -y install java-1.8.0-openjdk-headless
yum -y install sudo wget curl dos2unix unzip sed bc ant git php php-curl 

# make centos preparations
ln -s /etc/httpd /etc/apache2
mkdir /etc/httpd/conf-available
mkdir /etc/httpd/conf-enabled
echo IncludeOptional conf-enabled/*.conf >> /etc/httpd/conf/httpd.conf

# reverse proxy configuration
conf=/etc/apache2/conf-available/aktin-j2ee-reverse-proxy.conf
echo ProxyPreserveHost On > $conf
echo ProxyPass /aktin http://localhost:9090/aktin >> $conf
echo ProxyPassReverse /aktin http://localhost:9090/aktin >> $conf

echo LoadModule proxy_module libexec/apache2/mod_proxy.so >> /etc/httpd/conf/httpd.conf
echo LoadModule proxy_http_module libexec/apache2/mod_proxy_http.so >> /etc/httpd/conf/httpd.conf

apachectl restart

ln -s /var/www/html /var/webroot

#postgres
yum -y install postgresql-server postgresql-contrib
postgresql-setup initdb
systemctl enable postgresql
systemctl start postgresql

# echo enable remote access to postgres
cp $install_root/cent-postgres-remote-access.sh /opt/
dos2unix /opt/cent-postgres-remote-access.sh
/opt/cent-postgres-remote-access.sh

# ifconfig

# create postgres databases for i2b2
# cd $install_root
dos2unix $install_root/cent_auto.sh

# TODO dont write logfiles to /vagrant
LOG_DIR=$install_root/logs
if [ ! -d "$LOG_DIR" ]; then 
    mkdir $LOG_DIR
fi

# check java version and set it to jdk8 if not already (in debian with update-alternatives --config java)
#java -version

chmod -R o+x $install_root

ln -s $install_root /opt/aktin

$install_root/autoinstall.sh 2> $LOG_DIR/autoinstall.err.log
