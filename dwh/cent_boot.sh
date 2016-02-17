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

ln -s $conf /etc/apache2/conf-enabled/

echo LoadModule proxy_module libexec/apache2/mod_proxy.so >> /etc/httpd/conf/httpd.conf
echo LoadModule proxy_http_module libexec/apache2/mod_proxy_http.so >> /etc/httpd/conf/httpd.conf

apachectl restart

ln -s /var/www/html /var/webroot

#postgres
yum -y install postgresql-server postgresql-contrib
postgresql-setup initdb
systemctl enable postgresql
systemctl start postgresql

sudo -u postgres ant -f cent_build.xml change_pg_file
# chown postgres:postgres /var/lib/pgsql/data/pg_hba.conf
systemctl restart postgresql

ant -f cent_build.xml change_selinux_file

# create postgres databases for i2b2
dos2unix $install_root/cent_auto.sh

LOG_DIR=$install_root/logs
if [ ! -d "$LOG_DIR" ]; then 
    mkdir $LOG_DIR
fi

chmod -R o+x $install_root

ln -s $install_root /opt/aktin

#$install_root/cent_auto.sh 2> $LOG_DIR/autoinstall.err.log
