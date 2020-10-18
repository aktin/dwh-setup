#!/bin/bash

# script to install i2b2 with aktin-addon on ubuntu 20.04
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
# september 2020

# all version numbers of used software
readonly JAVA_VERSION=${version.java}
readonly WILDFLY_VERSION=${version.wildfly}
readonly PG_VERSION=${version.postgresql}
readonly JDBC_VERSION=${version.jdbc.driver}
readonly APACHE2_VERSION=${version.apache2}
readonly I2B2_VERSION=${version.i2b2}
readonly PHP_VERSION=${version.php}
readonly PYTHON_VERSION=${version.python}
readonly R_VERSION=${version.r}

readonly INSTALL_ROOT=$(pwd) # current directory with installation files
readonly INSTALL_PACKAGES=$INSTALL_ROOT/packages
readonly SQL_FILES=$INSTALL_ROOT/sql
readonly SCRIPT_FILES=$INSTALL_ROOT/scripts
readonly XML_FILES=$INSTALL_ROOT/xml

readonly WILDFLY_HOME=${path.wildfly.link}
readonly JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"
readonly JAVA_HOME=/usr/lib/jvm/java-$JAVA_VERSION-openjdk-amd64

# colors for console output
readonly WHI=${color.white}
readonly RED=${color.red}
readonly ORA=${color.orange}
readonly YEL=${color.yellow}
readonly GRE=${color.green}

# urls for packages to download
readonly URL_I2B2_WEBCLIENT=${url.i2b2.webclient}
readonly URL_WILDFLY=${url.wildfly}
readonly URL_JDBC_DRIVER=${url.jdbc.driver}
readonly URL_I2B2=${url.i2b2.war}

# create a logfile for this installation
readonly LOGFILE=${path.log.folder}/aktin_install_$(date +%Y_%h_%d_%H:%M).log
if [[ ! -d ${path.log.folder} ]]; then
    mkdir ${path.log.folder}
fi

# create link to this folder in ${path.install.home} for other files
if [[ ! -f ${path.install.link} ]]; then
	ln -s $(pwd) ${path.install.link}
fi





step_I(){
set -euo pipefail # stop installation on errors
echo
echo -e "${YEL}+++++ STEP I +++++ Installation der notwendigen Pakete${WHI}"
echo

# create timezone data to make installation non-interactive (tzdata needs this)
local TZ=Europe/Berlin
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# repository for php and python
apt-get update && apt-get install -y software-properties-common
add-apt-repository -y ppa:ondrej/php
add-apt-repository -y ppa:deadsnakes/ppa

# install packages
apt-get update && apt-get install -y \
curl sudo wget nano unzip libpq-dev \
openjdk-$JAVA_VERSION-jre-headless \
postgresql-$PG_VERSION \
apache2=$APACHE2_VERSION \
php$PHP_VERSION php$PHP_VERSION-common libapache2-mod-php$PHP_VERSION php$PHP_VERSION-curl \
r-base-core=$R_VERSION r-cran-lattice r-cran-xml
python$PYTHON_VERSION python3-pandas python3-numpy python3-requests python3-sqlalchemy python3-psycopg2 python3-postgresql python3-zipp python3-plotly python3-unicodecsv
}




step_II(){
set -euo pipefail # stop installation on errors
echo
echo -e "${YEL}+++++ STEP II +++++ Installation der i2b2-Datenbank${WHI}"
echo

service postgresql start
# count databases with name i2b2
if  [[ $(sudo -u postgres psql -l | grep "i2b2" | wc -l) == 0 ]]; then

	# create database i2b2 and respective users
	echo -e "${YEL}Eine Datenbank mit Namen i2b2 und entsprechenden Usern wird erstellt.${WHI}"
	sudo -u postgres psql -v ON_ERROR_STOP=1 -f $SQL_FILES/i2b2_postgres_init.sql
		
	# build i2b2 data and load into database
	echo -e "${YEL}Daten werden in die Datenbank i2b2 eingelesen.${WHI}"
	sudo -u postgres psql -d i2b2 -f $SQL_FILES/i2b2_db.sql
else
	echo -e "${ORA}Die Installation der i2b2-Datenbank wurde bereits durchgeführt.${WHI}"
fi
service postgresql stop
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
if [[ -n $(grep ";extension=curl" /etc/php/7.3/apache2/php.ini) ]]; then
	echo -e "${YEL}PHP-curl für apache2 wird aktiviert.${WHI}"
	sed -i 's/;extension=curl/extension=curl/' /etc/php/7.3/apache2/php.ini
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
else
	echo -e "${ORA}Die Proxy für apache2 wurde bereits konfiguriert.${WHI}"
fi
}




step_IV(){
set -euo pipefail # stop installation on errors
echo
echo -e "${YEL}+++++ STEP IV +++++ Installation von WildFly${WHI}"
echo

# download wildfly server into install destination and rename server to wildfly
if [[ ! -d /opt/wildfly ]]; then
	echo -e "${YEL}Der Wildfly-Server wird heruntergeladen und nach /opt entpackt.${WHI}"
	wget $URL_WILDFLY -P /tmp
	unzip /tmp/wildfly-$WILDFLY_VERSION.zip -d /opt
	mv /opt/wildfly-$WILDFLY_VERSION /opt/wildfly
else
	echo -e "${ORA}Der Wildfly-Server befindet sich bereits in /opt.${WHI}"
fi

# create link to wildfly folder in ${path.install.home}
if [[ ! -f ${path.wildfly.link} ]]; then
	echo -e "${YEL}Ein Link zum Wildfly-Server wird in ${path.install.home} abgelegt.${WHI}"
	ln -s /opt/wildfly ${path.wildfly.link}
else
	echo -e "${YEL}Ein Link für den Wildfly-Server ist bereits in ${path.install.home} vorhanden.${WHI}"
fi

# set wildfly to run as a service
if [[ ! -d /etc/default/wildfly ]]; then
	echo -e "${YEL}Ein /etc/init.d-Service wird für den Wildfly-Server erstellt.${WHI}"
	cp $WILDFLY_HOME/docs/contrib/scripts/init.d/wildfly-init-debian.sh /etc/init.d/wildfly
	mkdir /etc/default/wildfly
	cp $WILDFLY_HOME/docs/contrib/scripts/init.d/wildfly.conf /etc/default/wildfly
	echo JBOSS_HOME=\"$WILDFLY_HOME\" >> /etc/default/wildfly/wildfly-conf
	echo JBOSS_OPTS=\"-Djboss.http.port=9090 -Djboss.as.management.blocking.timeout=6000\" >> /etc/default/wildfly/wildfly-conf
else
	echo -e "${ORA}}Ein /etc/init.d-Service existiert bereits für den Wildfly-Server.${WHI}"
fi

# create user for wildfly server and give permissions to wildfly folder
if [[ -z $(grep "wildfly" /etc/passwd) ]]; then
	echo -e "${YEL}Der User wildfly für den Wildfly-Server wird erstellt.${WHI}"
	adduser --system --group --disabled-login wildfly
	chown -R wildfly:wildfly $WILDFLY_HOME
else
	echo -e "${ORA}Der User wildfly ist bereits vorhanden.${WHI}"
fi

# increase memory storage of java vm to 1g/2g
if [[ -z $(grep "Xms1024m -Xmx2g" $WILDFLY_HOME/bin/appclient.conf) ]]; then
	echo -e "${YEL}Java VM-Speicher für den Wildfly-Server wird erhöht.${WHI}"
	sed -i 's/-Xms64m -Xmx512m/-Xms1024m -Xmx2g/' $WILDFLY_HOME/bin/appclient.conf
	sed -i 's/-Xms64m -Xmx512m/-Xms1014m -Xmx2g/' $WILDFLY_HOME/bin/standalone.conf
else
	echo -e "${ORA}Der Wildfly-Speicher für Java VM wurde bereits erhöht.${WHI}"
fi

# change size limit of log rotation to 1g
if [[ -z $(grep "<rotate-size value=\"50m\"/>" $WILDFLY_HOME/standalone/configuration/standalone.xml) ]]; then
	echo -e "${YEL}Das Limit für die Log-Rotation des Wildfly-Servers wird erhöht.${WHI}"
	sed -i 's|<rotate-size value=\"50m\"/>|<rotate-size value=\"1g\"/>|' $WILDFLY_HOME/standalone/configuration/standalone.xml
else
	echo -e "${ORA}Das Limit für die Log-Rotation des Wildfly-Servers wurde bereits erhöht.${WHI}"
fi

# change port of wildfly from 8080 to 9090
if [[ -z $(grep "port:9090" $WILDFLY_HOME/standalone/configuration/standalone.xml) ]]; then
	echo -e "${YEL}Der Port des Wildfly-Servers wird von 8080 auf 9090 geändert.${WHI}"
	sed -i 's|<socket-binding name="http" port="${jboss.http.port:8080}"/>|<socket-binding name="http" port="${jboss.http.port:9090}"/>|' $WILDFLY_HOME/standalone/configuration/standalone.xml
else
	echo -e "${ORA}Der Port des Wildfly-Servers wurde bereits von 8080 auf 9090 geändert.${WHI}"
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
array=( crc im ont pm work )
for i in "${array[@]}"
do
	if [[ ! -f $WILDFLY_HOME/standalone/deployments/$i-ds.xml ]]; then
		echo -e "${YEL}$i-ds.xml wird nach $WILDFLY_HOME/standalone/deployments verschoben.${WHI}"
		cp $XML_FILES/$i-ds.xml $WILDFLY_HOME/standalone/deployments/
	else
		echo -e "${ORA}$i-ds.xml ist bereits in $WILDFLY_HOME/standalone/deployments vorhanden.${WHI}"
	fi
done
}




step_V(){
set -euo pipefail # stop installation on errors
echo
echo -e "${YEL}+++++ STEP V +++++ Installation der AKTIN Datenbank${WHI}"
echo

service postgresql start
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

# start wildfly server safely (JBOSS cli needs running server)
./wildfly_safe_start.sh

# change logging properties of wildfly server
if [[ $(grep -c "size-rotating-file-handler name=\"srf\"" $WILDFLY_HOME/standalone/configuration/standalone.xml) == 0 ]]; then
	echo -e "${YEL}Das Logging des Wildfly-Servers wird aktualisiert.${WHI}"
	$JBOSSCLI --file="$SCRIPT_FILES/wildfly_logging_update.cli"
else
	echo -e "${ORA}Das Logging des Wildfly-Servers wurde bereits aktualisiert.${WHI}"
fi

# increase deployment timeout of wildfly server
if [[ $(grep -c "deployment-timeout" $WILDFLY_HOME/standalone/configuration/standalone.xml) == 0 ]]; then
	echo -e "${YEL}Das Zeitlimit für das Deployment wird erhöht.${WHI}"
	$JBOSSCLI --file="$SCRIPT_FILES/wildfly_deployment_timeout.cli"
else
	echo -e "${ORA}Das Zeitlimit für das Deployment wurde bereits erhöht.${WHI}"
fi

# create aktin datasource
if [[ $(grep -c "jndi-name=\"java:jboss/datasources/AktinDS\"" $WILDFLY_HOME/standalone/configuration/standalone.xml) == 0 ]]; then
	echo -e "${YEL}Eine Datasource für AKTIN wird im Wildfly-Server generiert.${WHI}"
	$JBOSSCLI --file="$SCRIPT_FILES/aktin_datasource_create.cli"
else
	echo -e "${ORA}Die Datasource für AKTIN wurde bereits im Wildfly-Server generiert.${WHI}"
fi

# set new SMTP configuration
if [[ $(grep -c "mail-session name=\"AktinMailSession\"" $WILDFLY_HOME/standalone/configuration/standalone.xml) == 0 ]]; then 
	echo -e "${YEL}Die Konfiguration der Email wird vorgenommen.${WHI}"
	./email_create.sh
else
	echo -e "${ORA}Die Konfiguration der Email wurde bereits vorgenommen.${WHI}"
fi

# stop wildfly server safely
./wildfly_safe_stop.sh

# give wildfly user permission for aktin.properties
if [[ ! $(stat -c '%U' $INSTALL_ROOT/aktin.properties) == "wildfly" ]]; then
	echo -e "${YEL}Dem User wildfly werden Rechte für die Datei aktin.properties übergeben.${WHI}"
	chown wildfly:wildfly $INSTALL_ROOT/aktin.properties
else
	echo -e "${ORA}Der User wildfly besitzt bereits Rechte für die Datei aktin.properties.${WHI}"
fi

# copy aktin.properties into wildfly server
if [[ ! -f $WILDFLY_HOME/standalone/configuration/aktin.properties ]]; then
	echo -e "${YEL}Die Datei aktin.properties wird nach $WILDFLY_HOME/standalone/configuration kopiert.${WHI}"
	cp $INSTALL_ROOT/aktin.properties $WILDFLY_HOME/standalone/configuration/
else
	echo -e "${ORA}Die Datei aktin.properties befindet sich bereits in $WILDFLY_HOME/standalone/configuration.{WHI}"
fi

# create /var/lib/aktin and give permissions to wildfly user
if [[ ! -d /var/lib/aktin ]]; then
	echo -e "${YEL}Der Ordner /var/lib/aktin wird erstellt.${WHI}"
	mkdir -p /var/lib/aktin
	chown wildfly /var/lib/aktin
else
	echo -e "${ORA}Der Ordner /var/lib/aktin existiert bereits.${WHI}"
fi
}




step_VI(){
set -euo pipefail # stop installation on errors
echo
echo -e "${YEL}+++++ STEP V +++++ Ausführung des AKTIN-Update${WHI}"
echo

cd $INSTALL_PACKAGES
tar xvzf dwh-update-*.tar.gz

cd dwh-update
chmod +x aktin_update.sh # ToDo: Fix this
./aktin_update.sh
}




end_message(){
set -euo pipefail # stop installation on errors
echo
echo -e "${YEL}"
echo "Installation abgeschlossen!"
echo "Vielen Dank, dass Sie die AKTIN-Software verwenden."
echo 
echo -e "${RED}+++++ WICHTIG! +++++ ${WHI}"
echo -e "Um das AKTIN-Notaufnahmeregister zu nutzen, vergewissern Sie sich, dass Sie die Dateien "${GRE}"$INSTALL_ROOT/email.config"${WHI}" und "${GRE}"$INSTALL_ROOT/aktin.properties"${WHI}" vor der Installation richtig konfiguriert haben!"
echo
echo -e "${RED}+++++ WICHTIG! +++++ ${WHI}"
echo -e "Bitte melden Sie auftretende Fehler an it-support@aktin.org!"
echo
echo
}




main(){
set -euo pipefail # stop installation on errors
step_I | tee -a $LOGFILE
step_II | tee -a $LOGFILE
step_III | tee -a $LOGFILE
step_IV | tee -a $LOGFILE
step_V | tee -a $LOGFILE
step_VI | tee -a $LOGFILE
end_message | tee -a $LOGFILE
}

main
