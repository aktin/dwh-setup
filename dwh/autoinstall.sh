#!/bin/bash

cd /vagrant/i2b2_install
pwd
echo install jboss
if [ ! -d "../logs" ]; then 
    mkdir ../logs
fi
./install_jboss.sh > ../logs/install_jboss.log

cd /opt/jboss-as-7.1.1.Final/
pwd
ls standalone/deployments
ls bin
./bin/standalone.sh > /vagrant/logs/jboss_standalone_start.log
