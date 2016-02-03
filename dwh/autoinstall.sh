#!/bin/bash
MY_PATH=/vagrant

DATA_HOME=$MY_PATH/i2b2_install
LOG_DIR=$MY_PATH/logs
PACKAGES=$MY_PATH/packages

BASE_APPDIR=/opt
WILDFLY_HOME=/opt/wildfly-9.0.2.Final

# do not run this script if wildfly already present
# otherwise this will likely break the installation
if [ -f /etc/default/wildfly ]
then
	>&2 echo "Aborting $0, wildfly is already configured"	
	exit 1
fi

# create symlink for fixed configuration paths in i2b2
ln -s $WILDFLY_HOME /opt/jboss-as-7.1.1.Final
#ln -s $WILDFLY_HOME /opt/wildfly

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

if [ ! -d "$MY_PATH/temp_install" ]; then 
    mkdir $MY_PATH/temp_install
fi
cp -r -f $MY_PATH/i2b2_install/* $MY_PATH/temp_install
cd $MY_PATH/temp_install
ant -f prepare_build.xml change_properties

# cd $MY_PATH/i2b2_install

echo ant scripts
ant all 
# > $LOG_DIR/ant_jboss_install.log 2> $LOG_DIR/ant_jboss_install.err.log

# echo load aktin data
# sudo -u postgres psql -c "command"
# psql -c "COPY i2b2metadata.table_access TO '$MY_PATH/i2b2_install/db_aktin/i2b2metadata.table_access.data' (DELIMITER '|');" i2b2
# psql -c "COPY i2b2metadata.i2b2 TO '$MY_PATH/i2b2_install/db_aktin/i2b2metadata.i2b2.data' (DELIMITER '|');" i2b2
# psql -c "COPY i2b2demodata.concept_dimension TO '$MY_PATH/i2b2_install/db_aktin/i2b2demodata.concept_dimension.data' (DELIMITER '|');" i2b2
# sudo -u postgres psql -c "TRUNCATE i2b2metadata.table_access; TRUNCATE i2b2metadata.i2b2; TRUNCATE i2b2demodata.concept_dimension;" i2b2
sudo -u postgres psql -c "COPY i2b2metadata.table_access FROM '$MY_PATH/i2b2_install/db_aktin/i2b2metadata.table_access.data' (DELIMITER '|');" i2b2
sudo -u postgres psql -c "COPY i2b2metadata.i2b2 FROM '$MY_PATH/i2b2_install/db_aktin/i2b2metadata.i2b2.data' (DELIMITER '|');" i2b2
sudo -u postgres psql -c "COPY i2b2demodata.concept_dimension FROM '$MY_PATH/i2b2_install/db_aktin/i2b2demodata.concept_dimension.data' (DELIMITER '|');" i2b2

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
echo JBOSS_OPTS=\"-Djboss.http.port=9090\" >> /etc/default/wildfly

echo reload daemon cache
# reload daemon cache
systemctl daemon-reload

echo start jboss service
service wildfly start
# can also run /etc/init.d/wildfly start

echo link wildfly to autostart
ln -s /etc/init.d/wildfly /etc/rc3.d/S10wildfly
