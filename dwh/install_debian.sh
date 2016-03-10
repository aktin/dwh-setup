#!/usr/bin/env bash

# install_root=~/i2b2install
# install_root=/vagrant
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")/

# Enable backports
echo 'deb http://http.debian.net/debian jessie-backports main' >> /etc/apt/sources.list
apt-get update
apt-get install -y openjdk-8-jre-headless sudo wget curl dos2unix unzip sed bc ant postgresql

# install R libraries for reporting
apt-get install -y r-cran-xml r-cran-lattice

# web server
apt-get install -y libapache2-mod-php5 php5-curl 
## TODO libapache2-mod-proxy (or -proxy-http) missing?
# reverse proxy configuration
conf=/etc/apache2/conf-available/aktin-j2ee-reverse-proxy.conf
echo ProxyPreserveHost On > $conf
echo ProxyPass /aktin http://localhost:9090/aktin >> $conf
echo ProxyPassReverse /aktin http://localhost:9090/aktin >> $conf
## TODO a2enmod php??
a2enmod proxy_http
a2enconf aktin-j2ee-reverse-proxy
service apache2 reload

# restart apache to reload php modules
# otherwise, curl might not be available until next restart
service apache2 restart

# find localhost root and link it to /var/webroot used in build process
WEBROOT=$(cat /etc/apache2/sites-available/*default* | grep -m1 'DocumentRoot' | sed 's/DocumentRoot//g' | awk '{ printf "%s", $1}')
echo linking Documentroot $WEBROOT to /var/webroot
ln -s $WEBROOT /var/webroot

# link install root to this locations so autoinstaller knows where we are
ln -s $install_root /opt/aktin

install_root=/opt/aktin

# create postgres databases for i2b2
dos2unix $install_root/autoinstall.sh

# TODO dont write logfiles to /vagrant
LOG_DIR=$install_root/logs
if [ ! -d "$LOG_DIR" ]; then 
    mkdir $LOG_DIR
fi

chmod -R o+x $install_root

$install_root/autoinstall.sh 2> $LOG_DIR/autoinstall.err.log
