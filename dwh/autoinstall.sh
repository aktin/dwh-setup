#!/bin/bash
MY_PATH=/vagrant

DATA_HOME=$MY_PATH/i2b2_install
LOG_DIR=$MY_PATH/logs
PACKAGES=$MY_PATH/packages

BASE_APPDIR=/opt
WILDFLY_HOME=$BASE_APPDIR/wildfly-9.0.2.Final

# create symlink for fixed configuration paths
ln -s $WILDFLY_HOME /opt/jboss-as-7.1.1.Final

# create directory for logs if not existent
if [ ! -d "$LOG_DIR" ]; then 
    mkdir $LOG_DIR
fi

# TODO try without libaio1

# find localhost root and link it to /vagrant/webroot
WEBROOT=$(cat /etc/apache2/sites-available/*default* | grep -m1 'DocumentRoot' | sed 's/DocumentRoot//g' | awk '{ printf "%s", $1}')
echo linking Documentroot $WEBROOT to /var/webroot
ln -s $WEBROOT /var/webroot

# Postgres remote connections for debugging
echo enable remote access to postgres
cp $MY_PATH/postgres-remote-access.sh /opt/
dos2unix /opt/postgres-remote-access.sh
/opt/postgres-remote-access.sh

cd $MY_PATH/i2b2_install

echo ant scripts
ant all > $LOG_DIR/ant_jboss_install.log 2> $LOG_DIR/ant_jboss_install.err.log

# start jboss
# TODO start as service
$WILDFLY_HOME/bin/standalone.sh > $LOG_DIR/wildfly_standalone_start.log 2> $LOG_DIR/wildfly_standalone_start.err.log &

# to stop jboss:
# $JBOSS_HOME/bin/jboss-cli.sh --connect --command=:shutdown > $LOG_DIR/jbossstop.log 2> $LOG_DIR/jbossstop.err.log &
