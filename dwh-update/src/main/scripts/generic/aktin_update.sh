#! /bin/bash

# script to install aktin-update on ubuntu 20.04
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
# september 2020

readonly AKTIN_VERSION=${dwhJ2EEVersion}

readonly INSTALL_ROOT=${path.install.link}
readonly SQL_FILES=$INSTALL_ROOT/sql
readonly PACKAGES=$INSTALL_ROOT/packages

readonly WILDFLY_HOME=$INSTALL_DEST/wildfly

# colors for console output
readonly WHI=${color.white}
readonly RED=${color.red}
readonly ORA=${color.orange}
readonly YEL=${color.yellow}
readonly GRE=${color.green}


# stop wildfly server safely
cd $SCRIPT_FILES
./wildfly_safe_stop.sh

# remove all old dwh-j2ee.ears
if [[ -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*.ear ]]; then
	echo -e "${YEL}Alte dwh-j2ee.ear werden gelöscht.${WHI}"
	rm $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*
else
	echo -e "${ORA}In $WILDFLY_HOME/standalone/deployments sind keine dwh-j2ee.ear vorhanden.${WHI}"

# deploy aktin ear and give permissions to wildfly user
if [[ ! -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$AKTIN_VERSION.ear ]]; then
	echo -e "${YEL}dwh-j2ee-$AKTIN_VERSION.ear wird nach $WILDFLY_HOME/standalone/deployments verschoben.${WHI}"
	cp $PACKAGES/dwh-j2ee-$AKTIN_VERSION.ear $WILDFLY_HOME/standalone/deployments/
	chown wildfly:wildfly $WILDFLY_HOME/standalone/deployments/dwh-j2ee-$AKTIN_VERSION.ear
else
	echo -e "${ORA}dwh-j2ee-$AKTIN_VERSION.ear ist bereits in $WILDFLY_HOME/standalone/deployments vorhanden.${WHI}"
fi

# start wildfly server safely
cd $SCRIPT_FILES
./wildfly_safe_start.sh