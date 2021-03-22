#! /bin/bash

# script to install aktin-update on ubuntu 20.04
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
set -euo pipefail

readonly AKTIN_VERSION=${dwhJ2EEVersion}

readonly UPDATE_ROOT=$(pwd)
readonly UPDATE_PACKAGES=$UPDATE_ROOT/packages
readonly UPDATE_SCRIPTS=$UPDATE_ROOT/scripts

readonly WILDFLY_HOME=/opt/wildfly

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
echo -e "${YEL}+++++ AKTIN-Update : STEP A +++++ Deployment der EAR${WHI}"
echo

# stop wildfly if running
if systemctl is-active --quiet wildfly; then
	service wildfly stop
fi

# remove all old dwh-j2ee.ears
if [[ $(ls /opt/wildfly/standalone/deployments/ | grep -c dwh-j2ee-*) != 0 ]]; then
	echo -e "${YEL}Alte dwh-j2ee.ear werden gelöscht.${WHI}"
	rm $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*
else
	echo -e "${ORA}In $WILDFLY_HOME/standalone/deployments sind keine dwh-j2ee.ear vorhanden.${WHI}"
fi

# deploy aktin ear and give permissions to wildfly user
if [[ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$AKTIN_VERSION.ear ]]; then
	echo -e "${YEL}dwh-j2ee-$AKTIN_VERSION.ear wird nach $WILDFLY_HOME/standalone/deployments verschoben.${WHI}"
	cp $UPDATE_PACKAGES/dwh-j2ee-$AKTIN_VERSION.ear $WILDFLY_HOME/standalone/deployments/
	chown wildfly:wildfly $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$AKTIN_VERSION.ear
else
	echo -e "${ORA}dwh-j2ee-$AKTIN_VERSION.ear ist bereits in $WILDFLY_HOME/standalone/deployments vorhanden.${WHI}"
fi
}




step_B(){
set -euo pipefail
echo
echo -e "${YEL}+++++ AKTIN-Update : STEP B +++++ Konfiguration für den Upload stationärer Behandlungsdaten${WHI}"
echo

cd $WILDFLY_HOME/standalone/configuration

# backup and patch aktin.properties
c1=$(grep -cP '(^import.data.path=.*)' aktin.properties)
c2=$(grep -cP '(^import.script.path=.*)' aktin.properties)
c3=$(grep -cP '(^import.script.check.interval=.*)' aktin.properties)
if [[ $(($c1 + $c2 + $c3)) == 0 ]]; then
	echo -e "${YEL}Die aktin.properties wird für den Upload stationärer Behandlungsdaten gepatcht.${WHI}"
	cp aktin.properties $UPDATE_ROOT/aktin.properties.backup_$AKTIN_VERSION
	patch aktin.properties < $UPDATE_SCRIPTS/properties_file_import.patch
	chown wildfly:wildfly aktin.properties
elif [[ $(($c1 + $c2 + $c3)) == 3 ]]; then
	echo -e "${ORA}Die aktin.properties wurde bereits für den Upload stationärer Behandlungsdaten gepatcht.${WHI}"
else
	echo -e "${RED}Die aktin.properties enthält Fehler im Bezug auf die Schlüssel für den Upload stationärer Behandlungsdaten${WHI}"
fi

# create folder for import data
if [[ ! -d /var/lib/aktin/import ]]; then
	echo -e "${YEL}Der Ordner /var/lib/aktin/import wird erstellt.${WHI}"
	mkdir -p /var/lib/aktin/import
	chown wildfly:wildfly /var/lib/aktin/import
else
	echo -e "${ORA}Der Ordner /var/lib/aktin/import existiert bereits.${WHI}"
fi

# create folder for import scripts
if [[ ! -d /var/lib/aktin/import-scripts ]]; then
	echo -e "${YEL}Der Ordner /var/lib/aktin/import-scripts wird erstellt.${WHI}"
	mkdir -p /var/lib/aktin/import-scripts
	chown wildfly:wildfly /var/lib/aktin/import-scripts
else
	echo -e "${ORA}Der Ordner /var/lib/aktin/import existiert bereits.${WHI}"
fi

# copy p21importer.py to /var/lib/aktin/import-scripts
if [[ ! -f /var/lib/aktin/import-scripts/p21importer.py ]]; then
	echo -e "${YEL}Das P21-Importskript wird nach /var/lib/aktin/import-scripts kopiert.${WHI}"
	cp $UPDATE_SCRIPTS/p21importer.py /var/lib/aktin/import-scripts/
	chown wildfly:wildfly /var/lib/aktin/import-scripts/p21importer.py
else
	echo -e "${ORA}Das P21-Importskript ist bereits in /var/lib/aktin/import-scripts vorhanden.${WHI}"
fi

# update wildfly post-size for files with max 1 gb
if [[ $(grep -q "max-post-size" standalone.xml) ]]; then
	echo -e "${YEL}Die standalone.xml wird für den Upload größerer Dateien konfiguriert.${WHI}"
	sed -i 's|enable-http2=\"true\"/>|enable-http2=\"true\" max-post-size=\"1073741824\"/>|' standalone.xml
else
	echo -e "${ORA}Die standalone.xml wurde bereits für den Upload größerer Dateien konfiguriert.${WHI}"
fi
}




start_wildfly(){
# start wildfly if not running
if ! systemctl is-active --quiet wildfly; then
	service wildfly start
fi
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
start_wildfly | tee -a $LOGFILE
end_message | tee -a $LOGFILE
}

main
