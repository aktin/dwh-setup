#!/bin/bash
MY_PATH=/opt/aktin

DATA_HOME=$MY_PATH/i2b2_install
DATA_DEST=$MY_PATH/temp_install
LOG_DIR=$MY_PATH/logs
PACKAGES=$MY_PATH/packages

BASE_APPDIR=/opt
WILDFLY_HOME=$BASE_APPDIR/wildfly-9.0.2.Final
JBOSS7_DIR=/opt/jboss-as-7.1.1.Final 

# do not run this script if wildfly already present
# otherwise this will likely break the installation
if [ -f $JBOSS7_DIR ]
then
	>&2 echo "Aborting $0, wildfly is already configured"	
	exit 1
fi

# create symlink for fixed configuration paths in i2b2
ln -s $WILDFLY_HOME $JBOSS7_DIR

# create directory for logs if not existent
if [ ! -d "$LOG_DIR" ]; then 
    mkdir $LOG_DIR
fi

if [ ! -d "$DATA_DEST" ]; then 
    mkdir $DATA_DEST
fi
cp -r -f $DATA_HOME/* $DATA_DEST
cd $DATA_DEST
ant -f prepare_build.xml change_properties

echo ant scripts
ant -f build_cent.xml all 

#TODO
# add apache to autostart
# add wildfly to autostart

# restart server!
# apachectl restart
# /opt/wildfly-9.0.2.Final/bin/standalone.sh -Djboss.http.port=9090 > /opt/aktin/logs/wildfly.log &
