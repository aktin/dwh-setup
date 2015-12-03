#!/bin/bash

cd /vagrant/i2b2_install
pwd
echo install jboss
if [ ! -d "/vagrant/logs" ]; then 
    mkdir /vagrant/logs
fi
./install_jboss.sh > /vagrant/logs/install_jboss.log

ifconfig

cd /opt/jboss-as-7.1.1.Final/
pwd
# ./bin/standalone.sh > /vagrant/logs/jboss_standalone_start.log
