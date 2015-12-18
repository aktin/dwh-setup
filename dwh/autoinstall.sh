#!/bin/bash
MY_PATH=/vagrant

DATA_HOME=$MY_PATH/i2b2_install
LOG_DIR=$MY_PATH/logs
PACKAGES=$MY_PATH/packages

BASE_APPDIR=/opt
JBOSS_HOME=$BASE_APPDIR/jboss-as-7.1.1.Final

# create directory for logs if not existent
if [ ! -d "$LOG_DIR" ]; then 
    mkdir $LOG_DIR
fi


# already covered in bootstrap
apt-get update > $LOG_DIR/autoupdate_apt.log 2> $LOG_DIR/autoupdate_apt.err.log
apt-get install -y wget curl dos2unix >> $LOG_DIR/autoupdate_apt.log 2>> $LOG_DIR/autoupdate_apt.err.log

# install - shorten list
apt-get -q -y install openjdk-7-jre-headless >> $LOG_DIR/autoupdate_apt.log 2>> $LOG_DIR/autoupdate_apt.err.log
# no openjdk-7-jdk  needed
apt-get -q -y install aptitude unzip git apt-offline libcurl3 php5-curl apache2 libaio1 libapache2-mod-php5 perl sed bc ant postgresql >> $LOG_DIR/autoupdate_apt.log 2>> $LOG_DIR/autoupdate_apt.err.log
#apt-get -q -y install screen #for testing


#echo 'deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main' > /etc/apt/sources.list.d/pgdg.list
#wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
#apt-get update >> $LOG_DIR/autoupdate_apt.log 2>> $LOG_DIR/autoupdate_apt.err.log
#apt-get -q -y install  postgresql.9.4 >> $LOG_DIR/autoupdate_apt.log 2>> $LOG_DIR/autoupdate_apt.err.log

#apt-get -y dist-upgrade

# find localhost root and link it to /vagrant/webroot
WEBROOT=$(cat /etc/apache2/sites-available/*default* | grep -m1 'DocumentRoot' | sed 's/DocumentRoot//g' | awk '{ printf "%s", $1}')
echo linked Documentroot $WEBROOT to /var/webroot
ln -s $WEBROOT /var/webroot

echo enable remote access to postgres
cp $MY_PATH/postgres-remote-access.sh /opt/
dos2unix /opt/postgres-remote-access.sh
/opt/postgres-remote-access.sh

cd $MY_PATH/i2b2_install

echo ant scripts
ant all > $LOG_DIR/ant_jboss_install.log 2> $LOG_DIR/ant_jboss_install.err.log

# start jboss
$JBOSS_HOME/bin/standalone.sh > $LOG_DIR/jboss_standalone_start.log 2> $LOG_DIR/jboss_standalone_start.err.log &

# to stop jboss:
# $JBOSS_HOME/bin/jboss-cli.sh --connect --command=:shutdown > $LOG_DIR/jbossstop.log 2> $LOG_DIR/jbossstop.err.log &
