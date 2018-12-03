#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
INSTALL_ROOT=$(dirname "$SCRIPT")/

DATA_HOME=$INSTALL_ROOT/i2b2_install
DATA_DEST=$INSTALL_ROOT/temp_install
PACKAGES=$INSTALL_ROOT/packages

WILDFLY_HOME=/opt/wildfly-9.0.2.Final
JBOSS7_DIR=/opt/jboss-as-7.1.1.Final

LOGFILE=$INSTALL_ROOT/install.log # logfile for install log

echo
echo +++++ STEP 0 +++++ Installation der notwendigen Pakete | tee -a $LOGFILE
echo
yum clean all
yum -y update
yum -y install epel-release
yum -y install java-1.8.0-openjdk-headless
yum -y install sudo wget curl dos2unix unzip sed bc ant php php-curl openssh-server

echo
echo +++++ STEP 0.i +++++ CentOs HTTPD Konfiguration | tee -a $LOGFILE
echo
# make centos preparations
ln -s /etc/httpd /etc/apache2
mkdir /etc/httpd/conf-available
mkdir /etc/httpd/conf-enabled
echo IncludeOptional conf-enabled/*.conf >> /etc/httpd/conf/httpd.conf

# reverse proxy configuration
echo Reverse Proxy Konfigurierung | tee -a $LOGFILE
conf=/etc/apache2/conf-available/aktin-j2ee-reverse-proxy.conf
echo ProxyPreserveHost On > $conf
echo ProxyPass /aktin http://localhost:9090/aktin >> $conf
echo ProxyPassReverse /aktin http://localhost:9090/aktin >> $conf

ln -s $conf /etc/apache2/conf-enabled/

echo LoadModule proxy_module libexec/apache2/mod_proxy.so >> /etc/httpd/conf/httpd.conf
echo LoadModule proxy_http_module libexec/apache2/mod_proxy_http.so >> /etc/httpd/conf/httpd.conf

#apachectl restart
echo HTTPD ins Autostart übernehmen und starten | tee -a $LOGFILE
systemctl enable httpd 2>&1 | tee -a $LOGFILE
systemctl start httpd 2>&1 | tee -a $LOGFILE

# open port 80
echo Firewall Konfigurierung | tee -a $LOGFILE
firewall-cmd --zone=public --add-port=80/tcp --permanent 2>&1 | tee -a $LOGFILE
firewall-cmd --reload 2>&1 | tee -a $LOGFILE

echo linking Documentroot /var/www/html to /var/webroot | tee -a $LOGFILE
ln -s /var/www/html /var/webroot

#ln -s $INSTALL_ROOT /opt/aktin

#INSTALL_ROOT=/opt/aktin

echo
echo +++++ STEP 0.ii +++++ Postgres Konfiguration | tee -a $LOGFILE
echo
#postgres
yum -y install postgresql-server postgresql-contrib
postgresql-setup initdb 2>&1 | tee -a $LOGFILE
systemctl enable postgresql 2>&1 | tee -a $LOGFILE

sudo -u postgres cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.orig
cat /var/lib/pgsql/data/pg_hba.conf.orig | sudo -u postgres sed -r -e 's|(host\W+all\W+all\W+127.0.0.1/32\W+)ident|\1trust|' -e's|(host\W+all\W+all\W+::1/128\W+)ident|\1trust|' -e 's|(local\W+all\W+all\W+)peer|\1trust|' > /var/lib/pgsql/data/pg_hba.conf

systemctl start postgresql 2>&1 | tee -a $LOGFILE


echo
echo +++++ STEP 0.iii +++++ R Konfiguration | tee -a $LOGFILE
echo
# install R libraries for reporting, adding fedora repos
echo Über Fedora Repo R beziehen : | tee -a $LOGFILE
rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm 2>&1 | tee -a $LOGFILE
# preparations for r-xml
yum -y install libxml2 libxml2-devel 2>&1 | tee -a $LOGFILE
yum -y install R  2>&1 | tee -a $LOGFILE
Rscript -e 'install.packages("XML", repos="https://cran.rstudio.com/")'  2>&1 | tee -a $LOGFILE
Rscript -e 'install.packages("lattice", repos="https://cran.rstudio.com/")' 2>&1 | tee -a $LOGFILE


echo
echo +++++ STEP 0.iv +++++ Deactivierung von SELinux restart required | tee -a $LOGFILE
echo
sudo cp /etc/sysconfig/selinux $INSTALL_ROOT/selinux.origls

sudo cat $INSTALL_ROOT/selinux.orig | sudo sed 's|SELINUX=enforcing|SELINUX=disabled|' > /etc/sysconfig/selinux



echo
echo +++++ STEP I +++++ Links und Rechte | tee -a $LOGFILE
echo
chmod -R o+x $INSTALL_ROOT
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


echo
echo +++++ STEP I.ii +++++ Wildfly Anpassung | tee -a $LOGFILE
echo
# create symlink for fixed configuration paths in i2b2
ln -s $WILDFLY_HOME $JBOSS7_DIR | tee -a $LOGFILE
echo $WILDFLY_HOME nach $JBOSS7_DIR verlinkt | tee -a $LOGFILE


# up till now, the script can be rerun. but not if it dies while ant is running.
echo
echo +++++ STEP II +++++ Installation Wildfly und Einrichtung der Datenbanken via ANT | tee -a $LOGFILE
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
	echo "postgres.users.create=create_POSTGRESQL_users_cent" >> $buildfile
	# change project name TODO needs refining
	echo "db.project=demo" >> $buildfile
	echo "db.project.name=Demo" >> $buildfile
	echo "db.project.uname=i2b2_DEMO" >> $buildfile
	echo "db.hive.id=i2b2demo" >> $buildfile

	echo Installation Wildfly und i2b2 per ANT | tee -a $LOGFILE
	ant all 2>&1 | tee -a $LOGFILE

	cd $INSTALL_ROOT
fi

echo
echo +++++ STEP III +++++ Wildfly Einrichtung und zu Autostart hinzufügen | tee -a $LOGFILE
echo

ln -s $WILDFLY_HOME /opt/wildfly

if [ ! -f /etc/default/wildfly.conf ]; then
	echo erstelle /etc/default/wildfly.conf  | tee -a $LOGFILE

	touch /etc/default/wildfly.conf
	#  cp /opt/wildfly/bin/init.d/wildfly.conf /etc/default/wildfly.conf
	echo JBOSS_HOME=\"$WILDFLY_HOME\" >> /etc/default/wildfly.conf
	echo JBOSS_USER=wildfly >> /etc/default/wildfly.conf
	echo JBOSS_MODE=standalone >> /etc/default/wildfly.conf
	echo JBOSS_CONFIG=standalone.xml >> /etc/default/wildfly.conf
	echo JBOSS_CONSOLE_LOG=\"/var/log/wildfly/console.log\" >> /etc/default/wildfly.conf
	echo JBOSS_OPTS=\"-Djboss.http.port=9090 -Djboss.as.management.blocking.timeout=6000\" >> /etc/default/wildfly.conf
fi

if [ ! -f /etc/init.d/wildfly ] ; then
	echo kopiere den Wildfly init skript nach /etc/init.d/wildfly | tee -a $LOGFILE
	cp /opt/wildfly/bin/init.d/wildfly-init-redhat.sh /etc/init.d/wildfly
fi
systemctl daemon-reload 2>&1 | tee -a $LOGFILE

mkdir -p /var/log/wildfly

echo erstelle user wildfly  | tee -a $LOGFILE
useradd --system wildfly 2>&1 | tee -a $LOGFILE

echo rechte ändern  | tee -a $LOGFILE
chown -R wildfly:wildfly $WILDFLY_HOME 2>&1 | tee -a $LOGFILE
chown -R wildfly:wildfly /opt/wildfly 2>&1 | tee -a $LOGFILE
chown -R wildfly:wildfly /var/log/wildfly 2>&1 | tee -a $LOGFILE

echo wildfly service aktivieren | tee -a $LOGFILE
systemctl enable wildfly

echo start jboss service | tee -a $LOGFILE
systemctl start wildfly

echo
echo +++++ STEP IV +++++ Deployment der EAR und Ausführen des aktuellsten Updateskriptes | tee -a $LOGFILE
echo
tar xvzf $PACKAGES/dwh-update-${project.version}.tar.gz | tee -a $LOGFILE

RCol='\e[0m'; Red='\e[0;31m'; BRed='\e[1;31m'; Yel='\e[0;33m'; BYel='\e[1;33m'; Gre='\e[0;32m'; BGre='\e[1;32m'; Blu='\e[0;34m'; BBlu='\e[1;34m'; 
echo -e "${BRed}+++INFO+++${Gre}Sollte im folgenden der Skript unterbrochen werden, bitte nur den Updateskript in $INSTALL_ROOT/dwh-update ausführen.${RCol}" | tee -a $LOGFILE

$INSTALL_ROOT/dwh-update/aktin_dwh_update.sh

