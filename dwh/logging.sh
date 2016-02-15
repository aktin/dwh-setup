#!/bin/bash

d=`date +%Y_%m_%d_%H_%M`
logdir=/vagrant/logs/logs_$d

if [ ! -d "$logdir" ]; then 
    mkdir $logdir
    mkdir $logdir/apache2_server
    mkdir $logdir/postgres
fi
cd $logdir
cp /var/log/wildfly/console.log wildfly_console.log
cp /opt/wildfly-9.0.2.Final/standalone/log/server.log wildfly_standalone.log
cp -r /var/log/apache2/* apache2_server
cp /var/log/syslog syslog
cp -r /var/log/postgresql/* postgres
