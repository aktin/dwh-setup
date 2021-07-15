#! /bin/bash

# script to install aktin-update on ubuntu 20.04
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
set -euo pipefail

readonly AKTIN_VERSION=${version_dwh}

readonly UPDATE_ROOT=$(pwd)
readonly UPDATE_PACKAGES=$UPDATE_ROOT/packages
readonly UPDATE_SCRIPTS=$UPDATE_ROOT/scripts
readonly UPDATE_XML_FILES=$UPDATE_ROOT/xml

readonly WILDFLY_HOME=/opt/wildfly
readonly WILDFLY_CONFIGURATION=$WILDFLY_HOME/standalone/configuration
readonly JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}
readonly ORA=${color_orange}
readonly YEL=${color_yellow}
readonly GRE=${color_green}

# create a logfile for this update
readonly LOGFILE=$(pwd)/aktin_update_$(date +%Y_%h_%d_%H%M).log




step_A(){
set -euo pipefail
echo
echo -e "${YEL}+++++ AKTIN-Update : STEP A +++++ Undeployment und Löschen der alten EAR${WHI}"
echo

if systemctl is-active --quiet wildfly; then
	service wildfly stop
fi
# remove all old dwh-j2ee.ears
if [[ $(ls /opt/wildfly/standalone/deployments/ | grep -c dwh-j2ee-*) != 0 ]]; then
	echo -e "${YEL}Alte dwh-j2ee.ear werden gelöscht.${WHI}"
	rm $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*
else
	echo -e "${ORA}In $WILDFLY_HOME/standalone/deployments ist keine EAR vorhanden.${WHI}"
fi
if ! systemctl is-active --quiet wildfly; then
	service wildfly start
	sleep 30s
fi
}




step_B(){
set -euo pipefail
echo
echo -e "${YEL}+++++ AKTIN-Update : STEP B +++++ Konfiguration für den Upload stationärer Behandlungsdaten${WHI}"
echo

# create folder /var/lib/aktin/import
if [[ ! -d /var/lib/aktin/import ]]; then
	echo -e "${YEL}Der Ordner /var/lib/aktin/import wird erstellt.${WHI}"
	mkdir -p /var/lib/aktin/import
	chown wildfly:wildfly /var/lib/aktin/import
else
	echo -e "${ORA}Der Ordner /var/lib/aktin/import existiert bereits.${WHI}"
fi

# copy p21importer.py to /var/lib/aktin/import-scripts
if [[ ! -f /var/lib/aktin/import-scripts/p21importer.py ]]; then
	if [[ ! -d /var/lib/aktin/import-scripts ]]; then
		echo -e "${YEL}Der Ordner /var/lib/aktin/import-scripts wird erstellt.${WHI}"
		mkdir -p /var/lib/aktin/import-scripts
		chown wildfly:wildfly /var/lib/aktin/import-scripts
	else
		echo -e "${ORA}Der Ordner /var/lib/aktin/import existiert bereits.${WHI}"
	fi
	echo -e "${YEL}Das P21-Importskript wird nach /var/lib/aktin/import-scripts kopiert.${WHI}"
	cp $UPDATE_SCRIPTS/p21importer.py /var/lib/aktin/import-scripts/
	chown wildfly:wildfly /var/lib/aktin/import-scripts/p21importer.py
else
	if [[ $(grep -wc "@VERSION=${version_p21_import_script}" /var/lib/aktin/import-scripts/p21importer.py) == 0 ]]; then
		echo -e "${YEL}Das P21-Importskript existiert in einer älteren Version und wird aktualisiert.${WHI}"
		rm /var/lib/aktin/import-scripts/p21importer.py
		cp $UPDATE_SCRIPTS/p21importer.py /var/lib/aktin/import-scripts/
		chown wildfly:wildfly /var/lib/aktin/import-scripts/p21importer.py
	else
		echo -e "${ORA}Das P21-Importskript ist bereits in der neusten Version vorhanden.${WHI}"
	fi
fi

# update wildfly post-size for files with max 1 gb
if [[ -z $($JBOSSCLI --command="/subsystem=undertow/server=default-server/http-listener=default/:read-attribute(name=max-post-size)" | grep "1073741824") ]]; then
	echo -e "${YEL}Die standalone.xml wird für den Upload größerer Dateien konfiguriert.${WHI}"
	$JBOSSCLI --file="$UPDATE_SCRIPTS/wildfly_max-post-size.cli"
else
	echo -e "${ORA}Die standalone.xml wurde breits für den Upload größerer Dateien konfiguriert.${WHI}"
fi
}



step_C(){
set -euo pipefail
echo
echo -e "${YEL}+++++ AKTIN-Update : STEP C +++++ Anpassungen in der Wildfly-Umgebung${WHI}"
echo

# set wildfly to run as a systemd-service
if [[ ( ! -f /lib/systemd/system/wildfly.service ) || ( ! -f $WILDFLY_HOME/bin/launch.sh ) ]]; then
	echo -e "${YEL}Der Wildfly-Service wird von einem init.d-Service in einen systemd-Service umgewandelt.${WHI}"
	rm /etc/init.d/wildfly
	rm -r /etc/default/wildfly
	mkdir /etc/wildfly
	cp $WILDFLY_HOME/docs/contrib/scripts/systemd/wildfly.conf /etc/wildfly/
	cp $WILDFLY_HOME/docs/contrib/scripts/systemd/launch.sh $WILDFLY_HOME/bin/
	chown wildfly:wildfly $WILDFLY_HOME/bin/launch.sh
	cp $SCRIPT_FILES/wildfly.service /lib/systemd/system/
	cp -R $SCRIPT_FILES/postgresql.service /lib/systemd/system/
	systemctl daemon-reload
else
	echo -e "${ORA}Ein systemd-Service existiert bereits für den Wildfly-Server.${WHI}"
fi

if [[ ! -f $WILDFLY_HOME/standalone/deployments/aktin-ds.xml ]]; then
	echo -e "${YEL}Die Datasource für AKTIN wird von der standalone.xml nach $WILDFLY_HOME/standalone/deployments verschoben.${WHI}"
	$JBOSSCLI --command="data-source remove --name=AktinDS"
	cp $UPDATE_XML_FILES/aktin-ds.xml $WILDFLY_HOME/standalone/deployments/
	service wildfly restart
else
	echo -e "${ORA}Die Datei aktin-ds.xml ist bereits in $WILDFLY_HOME/standalone/deployments vorhanden.${WHI}"
fi
}




step_D(){
set -euo pipefail
echo
echo -e "${YEL}+++++ AKTIN-Update : STEP D +++++ Patch der aktin.properties und Deployment der neuen EAR${WHI}"
echo

if systemctl is-active --quiet wildfly; then
	service wildfly stop
fi
# check if aktin.properties is in configuration folder
if [[ ! -f $WILDFLY_CONFIGURATION/aktin.properties ]]; then
	echo -e "${YEL}Die aktin.properties wird nach $WILDFLY_CONFIGURATION verschoben.${WHI}"
	cp $UPDATE_ROOT/aktin.properties $WILDFLY_CONFIGURATION/aktin.properties
	chown wildfly:wildfly aktin.properties
fi

# patch aktin.properties if necessary
c1=$(echo $(grep -cP '(^import.data.path=.*)' $WILDFLY_CONFIGURATION/aktin.properties))
c2=$(echo $(grep -cP '(^import.script.path=.*)' $WILDFLY_CONFIGURATION/aktin.properties))
c3=$(echo $(grep -cP '(^import.script.timeout=.*)' $WILDFLY_CONFIGURATION/aktin.properties))
if [[ $(($c1 + $c2 + $c3)) == 0 ]]; then
	echo -e "${YEL}Die aktin.properties wird für den Upload stationärer Behandlungsdaten gepatcht.${WHI}"
	patch $WILDFLY_CONFIGURATION/aktin.properties < $UPDATE_SCRIPTS/properties_file_import.patch
	chown wildfly:wildfly $WILDFLY_CONFIGURATION/aktin.properties
elif [[ $(($c1 + $c2 + $c3)) == 3 ]]; then
	echo -e "${ORA}Die aktin.properties wurde bereits für den Upload stationärer Behandlungsdaten gepatcht.${WHI}"
else
	echo -e "${RED}Die aktin.properties enthält Fehler im Bezug auf die Schlüssel für den Upload stationärer Behandlungsdaten${WHI}"
fi

c1=$(echo $(grep -cP '(^rscript.timeout=.*)' $WILDFLY_CONFIGURATION/aktin.properties))
c2=$(echo $(grep -cP '(^rscript.debug=.*)' $WILDFLY_CONFIGURATION/aktin.properties))
if [[ $(($c1 + $c2)) == 0 ]]; then
	echo -e "${YEL}Die aktin.properties wird für neue Schlüssel im Rscript gepatcht.${WHI}"
	patch $WILDFLY_CONFIGURATION/aktin.properties < $UPDATE_SCRIPTS/properties_rscript.patch
	chown wildfly:wildfly $WILDFLY_CONFIGURATION/aktin.properties
elif [[ $(($c1 + $c2)) == 2 ]]; then
	echo -e "${ORA}Die aktin.properties wurde bereits für neue Schlüsseln im Rscript gepatcht.${WHI}"
else
	echo -e "${RED}Die aktin.properties enthält Fehler im Bezug auf die neuen Schlüssel im Rscript${WHI}"
fi

# deploy aktin ear and give permissions to wildfly user
if [[ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$AKTIN_VERSION.ear ]]; then
	echo -e "${YEL}dwh-j2ee-$AKTIN_VERSION.ear wird nach $WILDFLY_HOME/standalone/deployments verschoben.${WHI}"
	cp $UPDATE_PACKAGES/dwh-j2ee-$AKTIN_VERSION.ear $WILDFLY_HOME/standalone/deployments/
	chown wildfly:wildfly $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$AKTIN_VERSION.ear
else
	echo -e "${ORA}dwh-j2ee-$AKTIN_VERSION.ear ist bereits in $WILDFLY_HOME/standalone/deployments vorhanden.${WHI}"
fi
if ! systemctl is-active --quiet wildfly; then
	service wildfly start
	sleep 30s
fi
}




start_services(){
set -euo pipefail # stop installation on errors
service apache2 start
service postgresql start
service wildfly start
}

end_message(){
set -euo pipefail # stop installation on errors
echo
echo -e "${YEL}Update erfolgreich abgeschlossen!${WHI}"
echo
}

main(){
set -euo pipefail
step_A | tee -a $LOGFILE
step_B | tee -a $LOGFILE
step_C | tee -a $LOGFILE
step_D | tee -a $LOGFILE
start_services | tee -a $LOGFILE
end_message | tee -a $LOGFILE
}

main
