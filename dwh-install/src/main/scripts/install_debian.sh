#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")/
${install_root1}
${install_root2}

MY_PATH=$install_root

DATA_HOME=$MY_PATH/i2b2_install
DATA_DEST=$MY_PATH/temp_install
PACKAGES=$MY_PATH/packages

WILDFLY_HOME=/opt/wildfly-9.0.2.Final
JBOSS7_DIR=/opt/jboss-as-7.1.1.Final 

# Enable backports
echo 'deb http://http.debian.net/debian jessie-backports main' >> /etc/apt/sources.list
apt-get update
apt-get install -y openjdk-8-jre-headless sudo wget curl dos2unix unzip sed bc ant postgresql apache2

# install R libraries for reporting
apt-get install -y r-cran-xml r-cran-lattice

# web server
apt-get install -y libapache2-mod-php5 php5-curl openssh-server
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
# ln -s $install_root /opt/aktin

# install_root=/opt/aktin

# create directory for logs if not existent
# TODO dont write logfiles to /vagrant
LOG_DIR=$install_root/logs
if [ ! -d "$LOG_DIR" ]; then 
    mkdir -p $LOG_DIR
    chmod -R 777 $LOG_DIR
fi

# chmod -R o+x $install_root


#autoinstall script

# do not run this script if wildfly already present
# otherwise this will likely break the installation
if [ -f /etc/default/wildfly ]
then
	>&2 echo "Aborting $0, wildfly is already configured"	
	exit 1
fi

# create symlink for fixed configuration paths in i2b2
ln -s $WILDFLY_HOME $JBOSS7_DIR

if [ ! -d "$DATA_DEST" ]; then 
    mkdir $DATA_DEST
    chmod -R 777 $DATA_DEST
fi
cp -r -f $DATA_HOME/* $DATA_DEST
cd $DATA_DEST

buildfile=build.properties
# add some system and build dependent parameters for the ant build
echo "# system generated properties for ant build" >> $buildfile
echo "ant.installdata.dir=${DATA_DEST}" >> $buildfile
echo "i2b2.src.dir=${DATA_DEST}/i2b2_src" >> $buildfile
echo "packages.dir=${PACKAGES}" >> $buildfile
echo "install-log.dir=${LOG_DIR}/ant-install" >> $buildfile
# add wildfly data
echo "app.base.dir=/opt" >> $buildfile
echo "jboss.home=${WILDFLY_HOME}" >> $buildfile
# system dependent postgres sql call
echo "postgres.users.create=create_POSTGRESQL_users" >> $buildfile
# change project name TODO needs refining
echo "db.project=demo" >> $buildfile
echo "db.project.name=Demo" >> $buildfile
echo "db.project.uname=i2b2_DEMO" >> $buildfile
echo "db.hive.id=i2b2demo" >> $buildfile

echo ant scripts
ant all 

##### set up ontology to postgresc

CDATMPDIR=/var/tmp/cda-ontology
mkdir $CDATMPDIR

touch update_sql.log
echo "update ontologies to ${org.aktin:cda-ontology:jar.version}" 2>&1 | tee -a update_sql.log
# unzip the sql jar 
unzip $PACKAGES/cda-ontology-${org.aktin:cda-ontology:jar.version}.jar -d $CDATMPDIR
chmod 777 -R $CDATMPDIR

# call sql script files. no console output since spamming
echo "update metadata " 2>&1 | tee -a update_sql.log
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/meta.sql" 2>&1 >> update_sql.log
echo "update crcdata " 2>&1 | tee -a update_sql.log
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/data.sql" 2>&1 >> update_sql.log

# remove temp directory
rm -r $CDATMPDIR


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

# make 0.7 changes with aktin_dwh_07_config.sh
$install_root/aktin_dwh_07_config.sh

echo start jboss service
service wildfly start
# can also run /etc/init.d/wildfly start

echo link wildfly to autostart
# better use update-rc.d instead of creating manual links
ln -s /etc/init.d/wildfly /etc/rc3.d/S10wildfly
