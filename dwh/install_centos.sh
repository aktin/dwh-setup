#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")/

yum clean all
yum -y update
yum -y install java-1.8.0-openjdk-headless
yum -y install sudo wget curl dos2unix unzip sed bc ant git php php-curl 

# install R libraries for reporting
yum -y install r-xml

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

ln -s $install_root /opt/aktin

install_root=/opt/aktin

#postgres
yum -y install postgresql-server postgresql-contrib
postgresql-setup initdb
systemctl enable postgresql

sudo -u postgres cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.orig
cat /var/lib/pgsql/data/pg_hba.conf.orig | sudo -u postgres sed -r -e 's|(host\W+all\W+all\W+127.0.0.1/32\W+)ident|\1trust|' -e's|(host\W+all\W+all\W+::1/128\W+)ident|\1trust|' -e 's|(local\W+all\W+all\W+)peer|\1trust|' > /var/lib/pgsql/data/pg_hba.conf

systemctl start postgresql

sudo cp /etc/sysconfig/selinux $install_root/selinux.orig
sudo cat $install_root/selinux.orig | sudo sed 's|SELINUX=enforcing|SELINUX=disabled|' > /etc/sysconfig/selinux

dos2unix $install_root/cent_auto.sh

LOG_DIR=$install_root/logs
if [ ! -d "$LOG_DIR" ]; then 
    mkdir $LOG_DIR
fi

chmod -R o+x $install_root

$install_root/cent_auto.sh 2> $LOG_DIR/autoinstall.err.log
