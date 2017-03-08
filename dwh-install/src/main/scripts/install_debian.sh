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

echo
echo +++++ STEP 0 +++++ Installation der notwendigen Pakete | tee -a $LOGFILE
echo
# Enable backports
if [ $(grep -e "^deb http://http.debian.net/debian jessie-backports main" /etc/apt/sources.list) -le 0 ] ; then
	echo 'deb http://http.debian.net/debian jessie-backports main' >> /etc/apt/sources.list
fi

apt-get update
apt-get install -y ca-certificates-java
apt-get install -y openjdk-8-jre-headless 
apt-get install -y sudo wget curl dos2unix unzip sed bc ant postgresql apache2

# install R libraries for reporting
apt-get install -y r-cran-xml r-cran-lattice

# web server
apt-get install -y libapache2-mod-php5 php5-curl openssh-server

echo
echo +++++ STEP 0.01 +++++ HTTP Konfigurationen | tee -a $LOGFILE
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


echo
echo +++++ STEP 1 +++++ Prüfung aktin.properties und email.config | tee -a $LOGFILE
echo
count=0
if [ ! -f $INSTALL_ROOT/lib/aktin.properties ] ; then
	echo Bitte die Datei $INSTALL_ROOT/aktin.properties mit Ihren Daten füllen und nach $INSTALL_ROOT/lib/ kopieren : | tee -a $LOGFILE 
	echo nano $INSTALL_ROOT/aktin.properties | tee -a $LOGFILE
	echo cp $INSTALL_ROOT/aktin.properties $INSTALL_ROOT/lib/ | tee -a $LOGFILE
	echo  | tee -a $LOGFILE
	count=1
fi
if [ ! -f $INSTALL_ROOT/lib/email.config ] ; then
	echo Bitte die Datei $INSTALL_ROOT/email.config mit Ihren Daten füllen und nach $INSTALL_ROOT/lib/ kopieren :  | tee -a $LOGFILE
	echo nano $INSTALL_ROOT/email.config | tee -a $LOGFILE
	echo cp $INSTALL_ROOT/email.config $INSTALL_ROOT/lib/ | tee -a $LOGFILE
	echo  | tee -a $LOGFILE
	count=1
fi
if [ $count -gt 0 ]; then
	RCol='\e[0m'
	Red='\e[0;31m'
	echo -e "${Red} Das Skript wird jetzt beendet. Bitte rufen Sie es erneut auf, wenn Sie die notwendigen Änderungen durchgeführt haben${RCol}" | tee -a $LOGFILE
	echo  | tee -a $LOGFILE
	exit 1
fi


# link install root to this locations so autoinstaller knows where we are
# ln -s $INSTALL_ROOT /opt/aktin
# INSTALL_ROOT=/opt/aktin

echo
echo +++++ STEP 2 +++++ Links und Rechte | tee -a $LOGFILE
echo

echo
echo +++++ STEP 2.01 +++++ Log Ordner | tee -a $LOGFILE
echo
# create directory for logs if not existent
# TODO dont write logfiles to /vagrant
LOG_DIR=$INSTALL_ROOT/logs
if [ ! -d "$LOG_DIR" ]; then 
    mkdir -p $LOG_DIR
    chmod -R 777 $LOG_DIR
fi

# chmod -R o+x $INSTALL_ROOT

echo
echo +++++ STEP 2.02 +++++ Wildfly Anpassung | tee -a $LOGFILE
echo
# create symlink for fixed configuration paths in i2b2
ln -s $WILDFLY_HOME $JBOSS7_DIR | tee -a $LOGFILE




# up till now, the script can be rerun. but not if it dies while ant is running.

echo
echo +++++ STEP 3 +++++ Installation via ANT | tee -a $LOGFILE
echo
if [ ! -d "$DATA_DEST" ]; then 
    mkdir $DATA_DEST
    chmod -R 777 $DATA_DEST
fi
if [ -d $WILDFLY_HOME ] && [ -d $WILDFLY_HOME/standalone/deployments/i2b2.war ] ; then
	# i2b2 is already installed (or at least some part of it. abort! )
else 
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

	echo ant scripts | tee -a $LOGFILE
	ant all  2>&1 | tee -a $LOGFILE

	cd $INSTALL_ROOT
fi

echo
echo +++++ STEP 4 +++++ Set Up Wildfly in autostart and start it | tee -a $LOGFILE
echo
##### Set up wildfly


if [ -f /etc/default/wildfly ]
then
	>&2 echo "Aborting $0, wildfly is already configured"	
	# exit 1
else 
	# Create user
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

echo start jboss service | tee -a $LOGFILE
service wildfly start 2>&1 | tee -a $LOGFILE
# can also run /etc/init.d/wildfly start

echo link wildfly to autostart | tee -a $LOGFILE
# better use update-rc.d instead of creating manual links
ln -s /etc/init.d/wildfly /etc/rc3.d/S10wildfly | tee -a $LOGFILE


echo
echo +++++ STEP 5 +++++ AKTIN eigene Einstellunen   | tee -a $LOGFILE
echo
# AKTIN eigen
echo
echo +++++ STEP 5.01 +++++  Create /var/lib/aktin   | tee -a $LOGFILE
echo
if [ ! -d "/var/lib/aktin" ]; then 
    mkdir -p /var/lib/aktin 2>&1  | tee -a $LOGFILE
    chown wildfly /var/lib/aktin 2>&1  | tee -a $LOGFILE
    if [ ! -d "/var/lib/aktin" ]; then 
        echo +++WARNING+++ /var/lib/aktin not created  | tee -a $LOGFILE
	else
        echo /var/lib/aktin successfully created  | tee -a $LOGFILE
    fi 
else
    echo /var/lib/aktin present, no action necessary | tee -a $LOGFILE
fi

echo
echo +++++ STEP 5.02 +++++  Aktin.properties nach Wildfly kopieren | tee -a $LOGFILE
echo
cp -v $INSTALL_ROOT/lib/aktin.properties $WILDFLY_HOME/standalone/configuration/  2>&1 | tee -a $LOGFILE


echo
echo +++++ STEP 5.03 +++++ Update local DWH ontology | tee -a $LOGFILE
echo
SQLLOG=$INSTALL_ROOT/update_sql.log
touch $SQLLOG

# folder where the postgres user can call sql files
CDATMPDIR=/var/tmp/cda-ontology
mkdir $CDATMPDIR

echo "-- update ontology to ${org.aktin:cda-ontology:jar.version}" 2>&1 | tee -a $SQLLOG | tee -a $LOGFILE
# unzip the sql jar to the folder
unzip $INSTALL_ROOT/packages/cda-ontology-${org.aktin:cda-ontology:jar.version}.jar -d $CDATMPDIR
cp -v $INSTALL_ROOT/lib/remove_ont.sql $CDATMPDIR/sql/remove_ont.sql 2>&1  # copy the remove ont file 
chmod 777 -R $CDATMPDIR # change the permissions of the folder
# call sql script files. no console output
echo "-- remove old ontology" 2>&1  | tee -a $SQLLOG | tee -a $LOGFILE
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/remove_ont.sql" 2>&1 >> $SQLLOG
echo "-- update metadata" 2>&1  | tee -a $SQLLOG | tee -a $LOGFILE
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/meta.sql" 2>&1 >> $SQLLOG
echo "-- update crcdata" 2>&1  | tee -a $SQLLOG | tee -a $LOGFILE
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/data.sql" 2>&1 >> $SQLLOG
# remove temp directory
rm -r $CDATMPDIR


echo
echo +++++ STEP 5.04 +++++ Create AKTIN Database in postgres  | tee -a $LOGFILE
echo
# XXX check if the database or user exist. if not, then create. if yes. only update. Right now, creating while existing will return error, but continue with the code.
cp -v "$INSTALL_ROOT/lib/postgres_db_script.sh" /var/tmp/ | tee -a $LOGFILE
chmod a+rx /var/tmp/postgres_db_script.sh
su - postgres bash -c "/var/tmp/postgres_db_script.sh" 2>&1  | tee -a $LOGFILE
echo AKTIN database created  | tee -a $LOGFILE
rm /var/tmp/postgres_db_script.sh


# wilfly has to run, but not with j2ee
echo
echo +++++ STEP 5.05 +++++ Create Aktin Data source in wildfly  | tee -a $LOGFILE
echo
$INSTALL_ROOT/lib/wait_wildfly.sh 
wait_wildfly=$?

if [ $wait_wildfly -lt 0 ]; then
	echo "- wildfly state unstable. exiting running script. Check" | tee -a $LOGFILE
	echo "    ls $WILDFLY_HOME/standalone/deployments/dwh-j2ee*" | tee -a $LOGFILE
	exit -1
fi

existAktinDS=$( grep -c AktinDS $WILDFLY_HOME/standalone/configuration/standalone.xml)
echo "- $existAktinDS occurences of AKTINDS in Standalone.xml found" | tee -a $LOGFILE
if [ "$existAktinDS" -gt 0 ]
then
	$JBOSSCLI "data-source remove --name=AktinDS,/subsystem=datasources:read-resource" 2>&1 | tee -a $LOGFILE
	echo "- removed older aktin datasource "  | tee -a $LOGFILE
fi
# jboss will be reloaded at the end of this update script. changes will be made, but will only take effect after reload
$JBOSSCLI --file="$INSTALL_ROOT/lib/create_aktin_datasource.cli" 2>&1 | tee -a $LOGFILE
# xxx check result? 
echo "- created aktin datasource"  | tee -a $LOGFILE
# $WILDFLY_HOME/bin/jboss-cli.sh  --connect controller=127.0.0.1 --commands="reload" 2>&1 
# echo "reload" 2>&1 


echo
echo +++++ STEP 6 +++++  Email Einrichtung | tee -a $LOGFILE
echo
JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"

# get smtp settings
LOCAL_SETTING=$INSTALL_ROOT/email.config
. $LOCAL_SETTING

# not changeable parameters
sessionname=AktinMailSession
jndiname=java:jboss/mail/AktinMailSession
smtpbind=aktin-smtp-binding

count=$(($( grep -c "smtp-server outbound-socket-binding-ref=\"$smtpbind\"" $WILDFLY_HOME/standalone/configuration/standalone.xml )+$( grep -c "outbound-socket-binding name=\"$smtpbind\"" $WILDFLY_HOME/standalone/configuration/standalone.xml )+$( grep -c "mail-session name=\"$sessionname\"" $WILDFLY_HOME/standalone/configuration/standalone.xml )))
if [ $count -gt 0 ]; then 
	echo Email bereits eingestellt. Dieser Schritt wird übersprungen.  | tee -a $LOGFILE
	echo Für Änderungen bitte $INSTALL_ROOT/lib/email_config_reset.sh aufrufen und diesen Update erneut durchführen | tee -a $LOGFILE
else
	# create new settings
	$JBOSSCLI "/socket-binding-group=standard-sockets/remote-destination-outbound-socket-binding=$smtpbind:add(host=$smtphost, port=$smtpport)" 2>&1 | tee -a $LOGFILE
	$JBOSSCLI "/subsystem=mail/mail-session=$sessionname:add(jndi-name=$jndiname)" 2>&1 | tee -a $LOGFILE
	$JBOSSCLI "/subsystem=mail/mail-session=$sessionname/server=smtp:add(outbound-socket-binding-ref=$smtpbind, username=$smtpuser, password=$smtppass, tls=$usetls, ssl=$usessl)" 2>&1 | tee -a $LOGFILE
	$JBOSSCLI "/subsystem=mail/mail-session=$sessionname/:write-attribute(name=from, value=$mailfrom)" 2>&1 | tee -a $LOGFILE
fi


echo
echo +++++ STEP 7 +++++  restart Wildfly Service | tee -a $LOGFILE
echo
service wildfly Stop 2>&1 | tee -a $LOGFILE
service wildfly start 2>&1 | tee -a $LOGFILE


echo
echo +++++ STEP 8 +++++  Deploy new dwh-j2ee EAR | tee -a $LOGFILE
echo
if [ ! -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_VERSION.ear" ]; then 
	cp -v $INSTALL_ROOT/packages/dwh-j2ee-$NEW_VERSION.ear $WILDFLY_HOME/standalone/deployments/ 2>&1 | tee -a $LOGFILE
    echo "Waiting for deployment (max. 60 sec)..."
    COUNTER=0
	while [ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_VERSION.ear.deployed ] && [ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_VERSION.ear.failed ]    
    do
        sleep 1
        ((COUNTER++))
        if [ $COUNTER = "120" ]; then
                break
        fi
    done

	if [ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$NEW_VERSION.ear.deployed ]; then 
        echo +++WARNING+++ file not successfully deployed, check for file: dwh-j2ee-$NEW_VERSION.ear.deployed  | tee -a $LOGFILE
    else 
        echo EAR successfully deployed | tee -a $LOGFILE
    fi
else 
	echo +++WARNING+++ file already present, this should never happen | tee -a $LOGFILE
fi

echo
echo Thank you for using the AKTIN software.  | tee -a $LOGFILE
echo "Please report errors to it-support@aktin.org (include $LOGFILE)" | tee -a $LOGFILE
echo
echo +++++ End of Update Procedure +++++  | tee -a $LOGFILE