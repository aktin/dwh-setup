#! /bin/bash

# script to remove i2b2 with aktin-addon from ubuntu 20.04
# installed packages are not removed, only the components 'webclient','wildfly' and 'databases' are removed with their configuration
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
set -euo pipefail

readonly UPDATE_ROOT=$(pwd)
readonly SQL_FILES=/tmp/sql

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}
readonly ORA=${color_orange}
readonly YEL=${color_yellow}
readonly GRE=${color_green}

# create a logfile for this reset
readonly LOGFILE=$(pwd)/aktin_reset_$(date +%Y_%h_%d_%H:%M).log

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
echo -e "${YEL}+++++ STEP I +++++ Entfernung der Datenbanken i2b2 und aktin${WHI}"
echo

# copy sql folder to a location where postgres user can execute them
if [[ ! -d /tmp/sql ]]; then
echo -e "${YEL}SQL-Dateien werden nach /tmp kopiert.${WHI}"
mkdir $SQL_FILES
cp $UPDATE_ROOT/sql/* $SQL_FILES/
chmod 777 -R $SQL_FILES
fi

service postgresql start
# delete aktin database and respective users
if  [[ $(sudo -u postgres psql -l | grep "aktin" | wc -l) == 1 ]]; then
	echo -e "${YEL}Die Datenbank aktin und der entsprechende User werden entfernt.${WHI}"
	sudo -u postgres psql -f sql/aktin_postgres_drop.sql
else
	echo -e "${ORA}Die Datenbank aktin und der entsprechende User wurden bereits entfernt.${WHI}"
fi

# delete i2b2 database
# following steps of installation are redone:
# - creation of database and respective users
# - loading of i2b2 data into database
if  [[ $(sudo -u postgres psql -l | grep "i2b2" | wc -l) == 1 ]]; then
	echo -e "${YEL}Die Datenbank i2b2 und die entsprechenden User werden entfernt.${WHI}"
	sudo -u postgres psql -f sql/i2b2_postgres_drop.sql
else
	echo -e "${ORA}Die Datenbank i2b2 und die entsprechenden User wurden bereits entfernt.${WHI}"
fi
service postgresql stop

# delete sql folder from /tmp
if [[ -d /tmp/sql ]]; then
echo -e "${YEL}SQL-Dateien werden aus /tmp wieder gelöscht.${WHI}"
rm -r $SQL_FILES
fi
}




step_II(){
set -euo pipefail # stop reset on errors
echo
echo -e "${YEL}+++++ STEP II +++++ Entfernung des i2b2-Webclients${WHI}"
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
# - removing default username and pw in login dialog box
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
echo -e "${YEL}+++++ STEP III +++++ Entfernung des Wildfly-Servers${WHI}"
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
# - deployment of aktin.ear and given permission to user wildfly
if [[ -d /opt/wildfly ]]; then
	echo -e "${YEL}Der Wildfly-Server wird entfernt.${WHI}"
	rm -r /opt/wildfly
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
	chown -R root:root aktin.properties
else
	echo -e "${ORA}Der User wildfly wurde bereits entfernt.${WHI}"
fi
}




end_message(){
set -euo pipefail # stop installation on errors
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
end_message | tee -a $LOGFILE
}

main
