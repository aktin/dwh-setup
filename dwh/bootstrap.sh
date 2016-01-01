#!/usr/bin/env bash

install_root=~/i2b2install
install_root=/vagrant

# Enable backports
echo 'deb http://http.debian.net/debian jessie-backports main' >> /etc/apt/sources.list
apt-get update
apt-get install -y "openjdk-8-jre-headless"


apt-get install -y wget curl dos2unix unzip sed bc ant postgresql

# web server
apt-get install libapache2-mod-php5 php5-curl


ifconfig

# create postgres databases for i2b2
# cd $install_root
dos2unix /vagrant/autoinstall.sh

LOG_DIR=/vagrant/logs
if [ ! -d "$LOG_DIR" ]; then 
    mkdir $LOG_DIR
fi

/vagrant/autoinstall.sh 2> $LOG_DIR/autoinstall.err.log
