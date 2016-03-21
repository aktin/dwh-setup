#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")/

MY_PATH=$install_root

DATA_HOME=$MY_PATH/i2b2_install
DATA_DEST=$MY_PATH/temp_install
PACKAGES=$MY_PATH/packages

WILDFLY_HOME=/opt/wildfly-9.0.2.Final
JBOSS7_DIR=/opt/jboss-as-7.1.1.Final 

yum clean all
yum -y update
yum -y install java-1.8.0-openjdk-headless
yum -y install sudo wget curl dos2unix unzip sed bc ant php php-curl 

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

#apachectl restart
systemctl enable httpd
systemctl start httpd

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
    mkdir -p $LOG_DIR
    chmod -R 777 $LOG_DIR
fi

# install R libraries for reporting, adding fedora repos
rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
# preparations for r-xml
yum -y install libxml2 libxml2-devel
yum -y install R
Rscript -e 'install.packages("XML", repos="https://cran.rstudio.com/")'
Rscript -e 'install.packages("lattice", repos="https://cran.rstudio.com/")'

chmod -R o+x $install_root



#autoinstall script


# do not run this script if wildfly already present
# otherwise this will likely break the installation
if [ -f $JBOSS7_DIR ]
then
	>&2 echo "Aborting $0, wildfly is already configured"	
	exit 1
fi

# create symlink for fixed configuration paths in i2b2
ln -s $WILDFLY_HOME $JBOSS7_DIR

if [ ! -d "$DATA_DEST" ]; then 
    mkdir $DATA_DEST
fi
cp -r -f $DATA_HOME/* $DATA_DEST
cd $DATA_DEST
ant -f prepare_build.xml change_properties

echo manipulate ant build file for centOS
cp build.xml build.xml.backup
cat build.xml.backup | sed 's|create_POSTGRESQL_users|create_POSTGRESQL_users_cent|' > build.xml

echo ant scripts
ant all

#TODO
# add apache to autostart
# add wildfly to autostart

# restart server!
# apachectl restart
# /opt/wildfly-9.0.2.Final/bin/standalone.sh -Djboss.http.port=9090 > /opt/aktin/logs/wildfly.log &

