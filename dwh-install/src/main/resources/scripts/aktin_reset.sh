#! /bin/bash

# script to remove i2b2 with aktin-addon from ubuntu 20.04
# installed packages are not removed, only the components 'webclient','wildfly' and 'databases' with their configuration
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
# september 2020

readonly INSTALL_ROOT=$(dirname "$(pwd)") # current directory with installation files
readonly INSTALL_DEST=/opt # destination of aktin installation
readonly SQL_FILES=$INSTALL_ROOT/sql

# colors for console output
readonly WHI='\033[0m'
readonly RED='\e[1;31m'
readonly ORA='\e[0;33m'
readonly YEL='\e[1;33m'
readonly GRE='\e[0;32m'

# create a logfile for this reset
readonly LOGFILE=$INSTALL_DEST/aktin_log/aktin_remove_$(date +%Y_%h_%d_%H:%M).log
if [[ ! -d $INSTALL_DEST/aktin_log ]]; then
    mkdir $INSTALL_DEST/aktin_log
fi

# if running, stop apache2, postgresql and wildfly service
if  [[ ! $(service apache2 status | grep "not" | wc -l) == 1 ]]; then
	service apache2 stop
fi
if  [[ $(service postgresql status | grep "online" | wc -l) == 1 ]]; then
	service postgresql stop
fi
if  [[ ! $(service wildfly status | grep "not" | wc -l) == 1 ]]; then
	service wildfly stop
fi


step_I(){
set -euo pipefail # stop reset on errors
echo
echo -e "${YEL}+++++ STEP I +++++ Entfernung des Wildfly-Servers${WHI}"
echo

# remove wildfly folder
# following steps of installation are redone:
# - unzipping of wildfly into install destination and renaming
# - increase of java vm memory storage
# - port change from 8080 to 9090
# - deployment of i2b2.war
# - deployment of postgresql jdbc driver
# - deployment of i2b2 xml datasources
# - update of wildfly logging
# - increase of wildlfy deployment timeout
# - creation of aktin datasource
# - setting of smtp configuration
# - deployment of aktin.ear and given permussion to user wildfly
if [[ -d $INSTALL_DEST/wildfly ]]; then
	echo -e "${YEL}Der Wildfly-Server wird entfernt.${WHI}"
	rm -r $INSTALL_DEST/wildfly
else 
	echo -e "${ORA}Der Wildfly-Server wurde bereits entfernt.${WHI}"
fi

# remove wildfly service
if [[ -f /etc/init.d/wildfly || -d /etc/default/wildfly ]]; then
	echo -e "${YEL}Der /etc/init.d-Service des Wildfly-Servers wird entfernt.${WHI}"
	if [[ -f /etc/init.d/wildfly ]]; then
		rm /etc/init.d/wildfly
	fi
	if [[ -d /etc/default/wildfly ]]; then
		rm -r /etc/default/wildfly
	fi
else
	echo -e "${ORA}Der /etc/init.d-Service des Wildfly-Servers wurde bereits entfernt.${WHI}"
fi

# remove user wildfly and reset permission of aktin.properties
if [[ -n $(grep "wildfly" /etc/passwd) ]]; then
	echo -e "${YEL}Der User wildfly wird entfernt.${WHI}"
	userdel wildfly
	chown -R root:root $INSTALL_ROOT/aktin.properties
else
	echo -e "${ORA}Der User wildfly wurde bereits entfernt.${WHI}"
fi
}




step_II(){
set -euo pipefail # stop reset on errors
echo
echo -e "${YEL}+++++ STEP II +++++ Entfernung des apache2-Konfiguration${WHI}"
echo

# remove proxy configuration of apache2
if [[ -f /etc/apache2/conf-available/aktin-j2ee-reverse-proxy.conf ]]; then
	echo -e "${YEL}Die Proxy-Konfiguration von apache2 wird entfernt.${WHI}"
	rm /etc/apache2/conf-available/aktin-j2ee-reverse-proxy.conf
else
	echo -e "${ORA}Die Proxy-Konfiguration von apache2 wurde bereits entfernt.${WHI}"
fi

# deactivate php-curl extension for apache2
if [[ -z $(grep ";extension=curl" /etc/php/7.3/apache2/php.ini) ]]; then
	echo -e "${YEL}PHP-curl für apache2 wird deaktiviert.${WHI}"
 	sed -i 's/extension=curl/;extension=curl/' /etc/php/7.3/apache2/php.ini
else
	echo -e "${ORA}PHP-curl für apache2 wurde bereits deaktiviert.${WHI}"
fi

# remove var/www/html/webclient
# following steps of installation are redone:
# - unzipping of i2b2 webclient into /var/www/html and renaming
# - changing domain of i2b2 webclient to AKTIN
if [[ -d /var/www/html/webclient ]] ; then
	echo -e "${YEL}Der Webclient von i2b2 wird aus dem Apache2-Verzeichnis entfernt.${WHI}"
	rm -r /var/www/html/webclient
else
	echo -e "${ORA}Der Webclient von i2b2 wurde bereits aus dem Apache2-Verzeichnis entfernt.${WHI}"
fi

# remove var/lib/aktin
if [[ -d /var/lib/aktin ]]; then
	echo -e "${YEL}Der Ordner /var/lib/aktin wird entfernt.${WHI}"
	rm -r /var/lib/aktin
else
	echo -e "${ORA}Der Ordner /var/lib/aktin wurde bereits entfernt.${WHI}"
fi
}



step_III(){
set -euo pipefail # stop reset on errors
echo
echo -e "${YEL}+++++ STEP III +++++ Entfernung der Datenbanken i2b2 und aktin${WHI}"
echo

service postgresql start
# delete aktin database
if  [[ $(sudo -u postgres psql -l | grep "aktin" | wc -l) == 1 ]]; then
	echo -e "${YEL}Die Datenbank aktin und der entsprechende User werden entfernt.${WHI}"
	sudo -u postgres psql -f $SQL_FILES/aktin_postgres_drop.sql
else
	echo -e "${ORA}Die Datenbank aktin und der entsprechende User wurden bereits entfernt.${WHI}"
fi

# delete i2b2 database
# following steps of installation are redone:
# - creation of database and respective users
# - loading of i2b2 data into database
# - adding of aktin data to i2b2 database
if  [[ $(sudo -u postgres psql -l | grep "i2b2" | wc -l) == 1 ]]; then
	echo -e "${YEL}Die Datenbank i2b2 und die entsprechenden User werden entfernt.${WHI}"
	sudo -u postgres psql -f $SQL_FILES/i2b2_postgres_drop.sql
else
	echo -e "${ORA}Die Datenbank i2b2 und die entsprechenden User wurden bereits entfernt.${WHI}"
fi
service postgresql stop
}




final_steps(){
set -euo pipefail # stop reset on errors
echo 

# clean folder /tmp/
if [ -n "$(ls -A /tmp/)" ]; then
   	echo -e "${YEL}Der Ordner /tmp/ wird geleert.${WHI}"
	rm -r /tmp/*
else
   echo -e "${ORA}Der Ordner /tmp/ wurde bereits geleert.${WHI}"
fi

# end message
echo
echo -e "${YEL}"
echo "Reset abgeschlossen!"
echo 
echo "Alle Komponenten von i2b2 und AKTIN wurden entfernt. Installiete Pakete wurden nicht entfernt."
echo "Eine Neuinstallation der Komponenten ist nun möglich."
echo -e "${WHI}"
}




main(){
set -euo pipefail # stop reset on errors
step_I | tee -a $LOGFILE
step_II | tee -a $LOGFILE
step_III | tee -a $LOGFILE
final_steps | tee -a $LOGFILE
}

main