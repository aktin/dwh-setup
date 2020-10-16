#! /bin/bash

# script to install aktin-update on ubuntu 20.04
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
# september 2020

# current version of aktin
readonly AKTIN_VERSION=${dwhJ2EEVersion}

# colors for console output
readonly WHI='\033[0m'
readonly RED='\e[1;31m'
readonly ORA='\e[0;33m'
readonly YEL='\e[1;33m'
readonly GRE='\e[0;32m'

check wildlfy server


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