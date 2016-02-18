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
ant deploy_dwh_j2ee_ear

echo load aktin data
sudo -u postgres psql -c "\COPY i2b2metadata.table_access FROM '$DATA_DEST/db_aktin/i2b2metadata.table_access.data' (DELIMITER '|');" i2b2
sudo -u postgres psql -c "\COPY i2b2metadata.i2b2 FROM '$DATA_DEST/db_aktin/i2b2metadata.i2b2.data' (DELIMITER '|');" i2b2
sudo -u postgres psql -c "\COPY i2b2demodata.concept_dimension FROM '$DATA_DEST/db_aktin/i2b2demodata.concept_dimension.data' (DELIMITER '|');" i2b2

#TODO
# add apache to autostart
# add wildfly to autostart

# restart server!
# apachectl restart
# start wildfly