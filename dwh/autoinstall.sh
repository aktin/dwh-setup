#!/bin/bash
MY_PATH=/opt/aktin

DATA_HOME=$MY_PATH/i2b2_install
DATA_DEST=$MY_PATH/temp_install
LOG_DIR=$MY_PATH/logs
PACKAGES=$MY_PATH/packages

BASE_APPDIR=/opt
WILDFLY_HOME=$BASE_APPDIR/wildfly-9.0.2.Final
JBOSS7_DIR=$BASE_APPDIR/jboss-as-7.1.1.Final 

# do not run this script if wildfly already present
# otherwise this will likely break the installation
if [ -f /etc/default/wildfly ]
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

# TODO try without libaio1

# find localhost root and link it to /var/webroot
WEBROOT=$(cat /etc/apache2/sites-available/*default* | grep -m1 'DocumentRoot' | sed 's/DocumentRoot//g' | awk '{ printf "%s", $1}')
echo linking Documentroot $WEBROOT to /var/webroot
ln -s $WEBROOT /var/webroot

# Postgres remote connections for debugging
echo enable remote access to postgres
cp $MY_PATH/postgres-remote-access.sh /opt/
dos2unix /opt/postgres-remote-access.sh
/opt/postgres-remote-access.sh

if [ ! -d "$DATA_DEST" ]; then 
    mkdir $DATA_DEST
fi
cp -r -f $DATA_HOME/* $DATA_DEST
cd $DATA_DEST
ant -f prepare_build.xml change_properties

echo ant scripts
ant all 
ant deploy_dwh_j2ee_ear

echo load aktin data
sudo -u postgres psql -c "COPY i2b2metadata.table_access FROM '$DATA_DEST/db_aktin/i2b2metadata.table_access.data' (DELIMITER '|');" i2b2
sudo -u postgres psql -c "COPY i2b2metadata.i2b2 FROM '$DATA_DEST/db_aktin/i2b2metadata.i2b2.data' (DELIMITER '|');" i2b2
sudo -u postgres psql -c "COPY i2b2demodata.concept_dimension FROM '$DATA_DEST/db_aktin/i2b2demodata.concept_dimension.data' (DELIMITER '|');" i2b2

##### Set up wildfly
# Create user
adduser --system --group --disabled-login wildfly
chown -R wildfly:wildfly $WILDFLY_HOME

# Copy init.d script to start as service
cp $WILDFLY_HOME/bin/init.d/wildfly-init-debian.sh /etc/init.d/wildfly

echo define jboss service configurations
# Define startup configuration
echo > /etc/default/wildfly
echo JBOSS_HOME=\"$WILDFLY_HOME\" >> /etc/default/wildfly
echo JBOSS_OPTS=\"-Djboss.http.port=9090 -Djboss.as.management.blocking.timeout=6000\" >> /etc/default/wildfly

echo reload daemon cache
# reload daemon cache
systemctl daemon-reload

echo start jboss service
service wildfly start
# can also run /etc/init.d/wildfly start

echo link wildfly to autostart
# better use update-rc.d instead of creating manual links
ln -s /etc/init.d/wildfly /etc/rc3.d/S10wildfly
