#!/bin/bash

# script to install i2b2 with aktin-addon on ubuntu 20.04
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
set -euo pipefail

# all version numbers of used software
readonly JAVA_VERSION=${version_java}
readonly WILDFLY_VERSION=${version_wildfly}
readonly PG_VERSION=${version_postgresql}
readonly JDBC_VERSION=${version_jdbc_driver}
readonly APACHE2_VERSION=${version_apache2}
readonly I2B2_VERSION=${version_i2b2}

readonly UPDATE_ROOT=$(pwd)/dwh-update # directory of dwh-update with installation files
readonly SQL_FILES=/tmp/sql
readonly SCRIPT_FILES=$UPDATE_ROOT/scripts
readonly XML_FILES=$UPDATE_ROOT/xml

readonly WILDFLY_HOME=/opt/wildfly
readonly JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}
readonly ORA=${color_orange}
readonly YEL=${color_yellow}
readonly GRE=${color_green}

# urls for packages to download
readonly URL_I2B2_WEBCLIENT=${url_i2b2_webclient}
readonly URL_WILDFLY=${url_wildfly}
readonly URL_JDBC_DRIVER=${url_jdbc_driver}
readonly URL_I2B2=${url_i2b2_war}

# create a logfile for this installation
readonly LOGFILE=$(pwd)/aktin_install_$(date +%Y_%h_%d_%H%M).log

# unzip update.tar.gz to acces scripts within
tar xvzf packages/dwh-update-*.tar.gz
chmod +x dwh-update/*




step_I(){
set -euo pipefail # stop installation on errors
echo
echo -e "${YEL}+++++ STEP I +++++ Installation der notwendigen Pakete${WHI}"
echo

# create timezone data to make installation non-interactive (tzdata needs this)
local TZ=Europe/Berlin
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# install packages
apt-get update && apt-get install -y \
curl sudo wget nano unzip libpq-dev software-properties-common \
openjdk-$JAVA_VERSION-jre-headless \
postgresql-$PG_VERSION \
apache2=$APACHE2_VERSION \
php php-common libapache2-mod-php php-curl \
r-base-core r-cran-lattice r-cran-xml libcurl4-openssl-dev libssl-dev libxml2-dev r-cran-tidyverse \
python3 python3-pandas python3-numpy python3-requests python3-sqlalchemy python3-psycopg2 python3-postgresql python3-zipp python3-plotly python3-unicodecsv python3-gunicorn
}




step_II(){
set -euo pipefail # stop installation on errors
echo
echo -e "${YEL}+++++ STEP II +++++ Installation der i2b2- und AKTIN-Datenbank${WHI}"
echo

# copy sql folder to a location where postgres user can execute them
if [[ ! -d /tmp/sql ]]; then
	echo -e "${YEL}SQL-Dateien werden nach /tmp kopiert.${WHI}"
	mkdir $SQL_FILES
	cp $UPDATE_ROOT/sql/* $SQL_FILES/
	chmod 777 -R $SQL_FILES
fi

service postgresql start
# count databases with name i2b2
if  [[ $(sudo -u postgres psql -l | grep "i2b2" | wc -l) == 0 ]]; then

	# create database i2b2 and respective users
	echo -e "${YEL}Eine Datenbank mit Namen i2b2 und entsprechenden Usern wird erstellt.${WHI}"
	sudo -u postgres psql -v ON_ERROR_STOP=1 -f $SQL_FILES/i2b2_postgres_init.sql

	# build i2b2 data and load into database
	echo -e "${YEL}Terminologie-Daten werden in die Datenbank i2b2 eingelesen.${WHI}"
	sudo -u postgres psql -d i2b2 -f $SQL_FILES/i2b2_db.sql
else
	echo -e "${ORA}Die Installation der i2b2-Datenbank wurde bereits durchgeführt.${WHI}"
fi

# count databases with name aktin
if  [[ $(sudo -u postgres psql -l | grep "aktin" | wc -l) == 0 ]]; then

	# add aktin data to i2b2 database
	echo -e "${YEL}AKTIN-Daten werden der Datenbank i2b2 hinzugefügt.${WHI}"
	sudo -u postgres psql -d i2b2 -v ON_ERROR_STOP=1 -f $SQL_FILES/addon_i2b2metadata.i2b2.sql
	sudo -u postgres psql -d i2b2 -v ON_ERROR_STOP=1 -f $SQL_FILES/addon_i2b2crcdata.concept_dimension.sql

	# create database aktin and respective user
	echo -e "${YEL}Eine Datenbank mit Namen aktin und entsprechendem User wird erstellt.${WHI}"
	sudo -u postgres psql -v ON_ERROR_STOP=1 -f $SQL_FILES/aktin_postgres_init.sql
else
	echo -e "${ORA}Die Integration der AKTIN-Datenbank wurde bereits durchgeführt.${WHI}"
fi
service postgresql stop

# delete sql folder from /tmp
if [[ -d /tmp/sql ]]; then
	echo -e "${YEL}SQL-Dateien werden aus /tmp wieder gelöscht.${WHI}"
	rm -r $SQL_FILES
fi
}




step_III(){
set -euo pipefail # stop installation on errors
echo
echo -e "${YEL}+++++ STEP III +++++ Installation des i2b2-Webclient${WHI}"
echo

# download i2b2 webclient into apache2 web directory and rename it to webclient
if [[ ! -d /var/www/html/webclient ]]; then
	echo -e "${YEL}Der Webclient von i2b2 wird heruntergeladen und in das Apache2-Verzeichnis verschoben.${WHI}"
	wget $URL_I2B2_WEBCLIENT -P /tmp
	unzip /tmp/v$I2B2_VERSION.0002.zip -d /var/www/html/
	mv /var/www/html/i2b2-webclient-* /var/www/html/webclient
else
	echo -e "${ORA}Der Webclient von i2b2 befindet sich bereits im Apache2-Verzeichnis.${WHI}"
fi

# change domain of i2b2 webclient from edu.harvard to localhost
if [[ -z $(grep "AKTIN" /var/www/html/webclient/i2b2_config_data.js) ]]; then
	echo -e "${YEL}Die Domain des Webclient wird von Harvard auf AKTIN geändert.${WHI}"
	sed -i 's|name: \"HarvardDemo\",|name: \"AKTIN\",|' /var/www/html/webclient/i2b2_config_data.js
	sed -i 's|urlCellPM: \"http://services.i2b2.org/i2b2/services/PMService/\",|urlCellPM: \"http://127.0.0.1:9090/i2b2/services/PMService/\",|' /var/www/html/webclient/i2b2_config_data.js
else
	echo -e "${ORA}Die Domain des Webclient wurde bereits auf AKTIN geändert.${WHI}"
fi

# remove default username and pw in login dialog box
if [[ -n $(grep "loginDefaultUsername : \"demo\"" /var/www/html/webclient/js-i2b2/i2b2_ui_config.js) ]]; then
	echo -e "${YEL}Die voreingestellten Eingaben von Nutzer und Passwort werden entfernt.${WHI}"
	sed -i 's|loginDefaultUsername : \"demo\"|loginDefaultUsername : \"\"|' /var/www/html/webclient/js-i2b2/i2b2_ui_config.js
	sed -i 's|loginDefaultPassword : \"demouser\"|loginDefaultPassword : \"\"|' /var/www/html/webclient/js-i2b2/i2b2_ui_config.js
else
	echo -e "${ORA}Die voreingestellten Eingaben von Nutzer und Passwort wurden bereits entfernt.${WHI}"
fi

# activate php-curl extension for apache2
if [[ -n $(grep ";extension=curl" /etc/php/*/apache2/php.ini) ]]; then
	echo -e "${YEL}PHP-curl für apache2 wird aktiviert.${WHI}"
	sed -i 's/;extension=curl/extension=curl/' /etc/php/*/apache2/php.ini
else
	echo -e "${ORA}PHP-curl für apache2 wurde bereits aktiviert.${WHI}"
fi

# reverse proxy configuration (from wildfly 9090 to apache 80)
local CONF=/etc/apache2/conf-available/aktin-j2ee-reverse-proxy.conf
if [[ ! -f $CONF ]]; then
	echo -e "${YEL}Die Proxy für apache2 wird konfiguriert.${WHI}"
	echo "ProxyPreserveHost On" > $CONF
	echo "ProxyPass /aktin http://localhost:9090/aktin" >> $CONF
	echo "ProxyPassReverse /aktin http://localhost:9090/aktin" >> $CONF
	a2enmod proxy_http
	a2enconf aktin-j2ee-reverse-proxy

	if systemctl is-active --quiet apache2; then
		service apache2 restart
		service apache2 reload
	fi
else
	echo -e "${ORA}Die Proxy für apache2 wurde bereits konfiguriert.${WHI}"
fi
}




step_IV(){
set -euo pipefail # stop installation on errors
echo
echo -e "${YEL}+++++ STEP IV +++++ Installation des WildFly-Servers${WHI}"
echo

# download wildfly server into install destination and rename server to wildfly
if [[ ! -d $WILDFLY_HOME-$WILDFLY_VERSION ]]; then
	echo -e "${YEL}Der Wildfly-Server wird heruntergeladen und nach /opt entpackt.${WHI}"
	wget $URL_WILDFLY -P /tmp
	unzip /tmp/wildfly-$WILDFLY_VERSION.zip -d /opt
else
	echo -e "${ORA}Der Wildfly-Server befindet sich bereits in /opt.${WHI}"
fi

# create user for wildfly server and give permissions to wildfly folder
if [[ -z $(grep "wildfly" /etc/passwd) ]]; then
	echo -e "${YEL}Der User wildfly für den Wildfly-Server wird erstellt.${WHI}"
	adduser --system --group --disabled-login wildfly
	chown -R wildfly:wildfly $WILDFLY_HOME-$WILDFLY_VERSION
else
	echo -e "${ORA}Der User wildfly ist bereits vorhanden.${WHI}"
fi

# create link to wildfly folder in /opt
if [[ ! -L $WILDFLY_HOME && ! -d $WILDFLY_HOME ]]; then
	echo -e "${YEL}Ein Link zum Wildfly-Server wird in /opt/ abgelegt.${WHI}"
	ln -s $WILDFLY_HOME-$WILDFLY_VERSION $WILDFLY_HOME
else
	echo -e "${ORA}Ein Link für den Wildfly-Server ist bereits in /opt/ vorhanden.${WHI}"
fi

# set wildfly to run as a service
if [[ ! -f /lib/systemd/system/wildfly.service ]]; then
	echo -e "${YEL}Ein systemd-Service wird für den Wildfly-Server erstellt.${WHI}"
	mkdir /etc/wildfly
	cp $WILDFLY_HOME/docs/contrib/scripts/systemd/wildfly.conf /etc/wildfly/
	cp $WILDFLY_HOME/docs/contrib/scripts/systemd/launch.sh $WILDFLY_HOME/bin/
	chown wildfly:widlfly $WILDFLY_HOME/bin/launch.sh
	cp $SCRIPT_FILES/wildfly.service /lib/systemd/system/
	cp -R $SCRIPT_FILES/postgresql.service /lib/systemd/system/
	systemctl daemon-reload
else
	echo -e "${ORA}Ein systemd-Service existiert bereits für den Wildfly-Server.${WHI}"
fi

# increase memory storage of java vm to 1g/2g
if [[ -z $(grep "Xms1024m -Xmx2g" $WILDFLY_HOME/bin/appclient.conf) ]]; then
	echo -e "${YEL}Java VM-Speicher für den Wildfly-Server wird erhöht.${WHI}"
	sed -i 's/-Xms64m -Xmx512m/-Xms1024m -Xmx2g/' $WILDFLY_HOME/bin/appclient.conf
	sed -i 's/-Xms64m -Xmx512m/-Xms1024m -Xmx2g/' $WILDFLY_HOME/bin/standalone.conf
else
	echo -e "${ORA}Der Wildfly-Speicher für Java VM wurde bereits erhöht.${WHI}"
fi

# download i2b2.war (https://community.i2b2.org/wiki/) into wildfly
if [[ ! -f $WILDFLY_HOME/standalone/deployments/i2b2.war ]]; then
	echo -e "${YEL}i2b2.war wird nach $WILDFLY_HOME/standalone/deployments heruntergeladen.${WHI}"
	wget $URL_I2B2 -P $WILDFLY_HOME/standalone/deployments/
else
	echo -e "${ORA}i2b2.war ist bereits in $WILDFLY_HOME/standalone/deployments vorhanden.${WHI}"
fi

# download postgresql jdbc driver into wildfly
if [[ ! -f $WILDFLY_HOME/standalone/deployments/postgresql-$JDBC_VERSION.jar ]]; then
	echo -e "${YEL}postgresql-$JDBC_VERSION.jar wird nach $WILDFLY_HOME/standalone/deployments heruntergeladen.${WHI}"
	wget $URL_JDBC_DRIVER -P $WILDFLY_HOME/standalone/deployments/
else
	echo -e "${ORA}postgresql-$JDBC_VERSION.jar ist bereits in $WILDFLY_HOME/standalone/deployments vorhanden.${WHI}"
fi

# move datasource xml-files into wildfly
array=( crc im ont pm work aktin )
for i in "${array[@]}"
do
	if [[ ! -f $WILDFLY_HOME/standalone/deployments/$i-ds.xml ]]; then
		echo -e "${YEL}$i-ds.xml wird nach $WILDFLY_HOME/standalone/deployments verschoben.${WHI}"
		cp $XML_FILES/$i-ds.xml $WILDFLY_HOME/standalone/deployments/
	else
		echo -e "${ORA}$i-ds.xml ist bereits in $WILDFLY_HOME/standalone/deployments vorhanden.${WHI}"
	fi
done

# create /var/lib/aktin and give permissions to wildfly user
if [[ ! -d /var/lib/aktin ]]; then
	echo -e "${YEL}Der Ordner /var/lib/aktin wird erstellt.${WHI}"
	mkdir -p /var/lib/aktin
	chown wildfly /var/lib/aktin
else
	echo -e "${ORA}Der Ordner /var/lib/aktin existiert bereits.${WHI}"
fi

service wildfly start

# change port of wildfly from 8080 to 9090
echo -e "${YEL}Der Port des Wildfly-Servers wird von 8080 auf 9090 geändert.${WHI}"
$JBOSSCLI --file="$SCRIPT_FILES/wildfly_socket-binding.cli"

# change logging properties of wildfly server
echo -e "${YEL}Das Logging des Wildfly-Servers wird aktualisiert.${WHI}"
$JBOSSCLI --file="$SCRIPT_FILES/wildfly_logging.cli"

# increase deployment timeout of wildfly server
echo -e "${YEL}Das Zeitlimit für das Deployment wird erhöht.${WHI}"
$JBOSSCLI --file="$SCRIPT_FILES/wildfly_deployment_timeout.cli"

service wildfly stop
}




step_V(){
set -euo pipefail # stop installation on errors

cd $UPDATE_ROOT
./aktin_update.sh
}

start_services(){
set -euo pipefail # stop installation on errors
service apache2 start
service postgresql start
service wildfly start
}

add_autostart(){
set -euo pipefail # stop installation on errors
update-rc.d apache2 defaults
update-rc.d postgresql defaults
update-rc.d wildfly defaults
}

end_message(){
set -euo pipefail # stop installation on errors
echo
echo -e "${YEL}"
echo "Installation abgeschlossen!"
echo "Vielen Dank, dass Sie die AKTIN-Software verwenden."
echo
echo -e "${RED}+++++ WICHTIG! +++++ ${WHI}"
echo -e "Bitte melden Sie auftretende Fehler an ${GRE}it-support@aktin.org${WHI}!"
echo
}

main(){
set -euo pipefail # stop installation on errors
step_I | tee -a $LOGFILE
step_II | tee -a $LOGFILE
step_III | tee -a $LOGFILE
step_IV | tee -a $LOGFILE
start_services | tee -a $LOGFILE
add_autostart | tee -a $LOGFILE
step_V # update has its own logfile
end_message | tee -a $LOGFILE
}

main
