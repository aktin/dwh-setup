#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
INSTALL_ROOT=$(dirname "$SCRIPT")/
${install_root1}
${install_root2}
NEW_VERSION=0.7-SNAPSHOT

MY_PATH=$INSTALL_ROOT

DATA_HOME=$MY_PATH/i2b2_install
DATA_DEST=$MY_PATH/temp_install
PACKAGES=$MY_PATH/packages

WILDFLY_HOME=/opt/wildfly-9.0.2.Final
JBOSS7_DIR=/opt/jboss-as-7.1.1.Final

LOGFILE=$INSTALL_ROOT/install.log # logfile for install log

echo
echo +++++ STEP 0 +++++ Installation der notwendigen Pakete | tee -a $LOGFILE
echo
# Enable backports
#  http://ftp.de.debian.org/debian jessie-backports main
# http.debian.net/debian jessie-backports main
if [ $(grep -c -e "^deb http://ftp.de.debian.org/debian jessie-backports main" /etc/apt/sources.list) -le 0 ] ; then
	echo 'deb http://ftp.de.debian.org/debian jessie-backports main' >> /etc/apt/sources.list
	echo 'deb http://http.debian.net/debian jessie-backports main' >> /etc/apt/sources.list
fi

apt-get update
# apt-get install -y ca-certificates-java
# apt-get install -y openjdk-8-jre-headless
apt install -t jessie-backports -y openjdk-8-jre-headless ca-certificates-java
apt-get install -y sudo wget curl dos2unix unzip sed bc ant postgresql apache2

# install R libraries for reporting
apt-get install -y r-cran-xml r-cran-lattice

# web server
apt-get install -y libapache2-mod-php5 php5-curl openssh-server

echo
echo +++++ STEP 0.i +++++ HTTP Konfigurationen | tee -a $LOGFILE
echo
## TODO libapache2-mod-proxy (or -proxy-http) missing?
# reverse proxy configuration
echo Reverse Proxy Konfigurierung | tee -a $LOGFILE
if [ ! -f /etc/apache2/conf-available/aktin-j2ee-reverse-proxy.conf ] ; then
	echo aktin reverse proxy wird angelegt:  | tee -a $LOGFILE
	conf=/etc/apache2/conf-available/aktin-j2ee-reverse-proxy.conf
	echo ProxyPreserveHost On > $conf
	echo ProxyPass /aktin http://localhost:9090/aktin >> $conf
	echo ProxyPassReverse /aktin http://localhost:9090/aktin >> $conf
fi
## TODO a2enmod php??
a2enmod proxy_http 2>&1 | tee -a $LOGFILE
a2enconf aktin-j2ee-reverse-proxy 2>&1 | tee -a $LOGFILE

# reload and restart apache
echo Restart und Reload Apache | tee -a $LOGFILE
service apache2 reload 2>&1 | tee -a $LOGFILE
service apache2 restart 2>&1 | tee -a $LOGFILE

# find localhost root and link it to /var/webroot used in build process
WEBROOT=$(cat /etc/apache2/sites-available/*default* | grep -m1 'DocumentRoot' | sed 's/DocumentRoot//g' | awk '{ printf "%s", $1}')
echo linking Documentroot $WEBROOT to /var/webroot | tee -a $LOGFILE
ln -s $WEBROOT /var/webroot


# link install root to this locations so autoinstaller knows where we are
# ln -s $INSTALL_ROOT /opt/aktin
# INSTALL_ROOT=/opt/aktin

echo
echo +++++ STEP I +++++ Links und Rechte | tee -a $LOGFILE
echo
echo Links und Rechte | tee -a $LOGFILE

echo
echo +++++ STEP I.i +++++ Log Ordner | tee -a $LOGFILE
echo
# create directory for logs if not existent
# TODO dont write logfiles to /vagrant
LOG_DIR=$INSTALL_ROOT/logs
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p $LOG_DIR
    chmod -R 777 $LOG_DIR
fi
echo Logordner angelegt und Rechte angepasst. | tee -a $LOGFILE

# chmod -R o+x $INSTALL_ROOT

echo
echo +++++ STEP I.ii +++++ Wildfly Anpassung | tee -a $LOGFILE
echo
# create symlink for fixed configuration paths in i2b2
ln -s $WILDFLY_HOME $JBOSS7_DIR | tee -a $LOGFILE
echo $WILDFLY_HOME nach $JBOSS7_DIR verlinkt | tee -a $LOGFILE




# up till now, the script can be rerun. but not if it dies while ant is running.

echo
echo +++++ STEP II +++++ Installation via ANT | tee -a $LOGFILE
echo
if [ ! -d "$DATA_DEST" ]; then
    mkdir $DATA_DEST
    chmod -R 777 $DATA_DEST
fi
echo $DATA_DEST angelegt und Rechte angepasst | tee -a $LOGFILE

if [ -d $WILDFLY_HOME ] && [ -d $WILDFLY_HOME/standalone/deployments/i2b2.war ] ; then
	echo Wildfly installiert und i2b2 bereits in Wildfly vorhanden. | tee -a $LOGFILE
	# i2b2 is already installed (or at least some part of it. abort! )
else
	cp -r -f $DATA_HOME/* $DATA_DEST
	cd $DATA_DEST

	if [ ! -d "$PACKAGES" ]; then
	    mkdir -p $PACKAGES
	fi
	chmod -R 777 $PACKAGES

	buildfile=build.properties
	echo Anpassung von $buildfile | tee -a $LOGFILE
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

	echo Installation Wildfly und i2b2 per ANT | tee -a $LOGFILE
	ant all  2>&1 | tee -a $LOGFILE

	cd $INSTALL_ROOT
fi

echo
echo +++++ STEP III +++++ Wildfly Einrichtung und zu Autostart hinzufügen | tee -a $LOGFILE
echo
##### Set up wildfly
if [ ! -f /etc/default/wildfly ]
then
	# Create wildlfy user
	adduser --system --group --disabled-login wildfly 2>&1 | tee -a $LOGFILE
	chown -R wildfly:wildfly $WILDFLY_HOME 2>&1 | tee -a $LOGFILE

	# Copy init.d script to start as service
	cp -v $WILDFLY_HOME/bin/init.d/wildfly-init-debian.sh /etc/init.d/wildfly | tee -a $LOGFILE

	echo define jboss service configurations | tee -a $LOGFILE
	# Define startup configuration
	echo > /etc/default/wildfly
	echo JBOSS_HOME=\"$WILDFLY_HOME\" >> /etc/default/wildfly
	echo JBOSS_OPTS=\"-Djboss.http.port=9090 -Djboss.as.management.blocking.timeout=6000\" >> /etc/default/wildfly

	echo reload daemon cache | tee -a $LOGFILE
	# reload daemon cache
	systemctl daemon-reload
fi
	# >&2 echo "Aborting $0, wildfly is already configured"	
	# exit 1

echo start jboss service | tee -a $LOGFILE
service wildfly start 2>&1 | tee -a $LOGFILE
# can also run /etc/init.d/wildfly start

if [ ! -f /etc/rc3.d/S10wildfly ] ; then 
	echo link wildfly to autostart | tee -a $LOGFILE
	# better use update-rc.d instead of creating manual links
	ln -s /etc/init.d/wildfly /etc/rc3.d/S10wildfly | tee -a $LOGFILE
fi

echo
echo +++++ STEP IV +++++ Deployment der EAR und Ausführen des aktuellsten Updateskriptes | tee -a $LOGFILE
echo
tar xvzf $PACKAGES/dwh-update-${project.version}.tar.gz | tee -a $LOGFILE

RCol='\e[0m'; Red='\e[0;31m'; BRed='\e[1;31m'; Yel='\e[0;33m'; BYel='\e[1;33m'; Gre='\e[0;32m'; BGre='\e[1;32m'; Blu='\e[0;34m'; BBlu='\e[1;34m'; 
echo -e "${BRed}+++INFO+++${Gre}Sollte im folgenden der Skript unterbrochen werden, bitte nur den Updateskript in $INSTALL_ROOT/dwh-update ausführen.${RCol}" | tee -a $LOGFILE

$INSTALL_ROOT/dwh-update/aktin_dwh_update.sh
