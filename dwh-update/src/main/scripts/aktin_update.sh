#! /bin/bash

# script to install aktin-update on ubuntu 20.04
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
set -euo pipefail

readonly AKTIN_VERSION=${dwhJ2EEVersion}

readonly INSTALL_ROOT=${path.install.link}
readonly UPDATE_ROOT=$(pwd)
readonly UPDATE_PACKAGES=$UPDATE_ROOT/packages

readonly WILDFLY_HOME=${path.wildfly.link}

# colors for console output
readonly WHI=${color.white}
readonly RED=${color.red}
readonly ORA=${color.orange}
readonly YEL=${color.yellow}
readonly GRE=${color.green}

# create a logfile for this update
readonly LOGFILE=${path.log.folder}/aktin_update_$(date +%Y_%h_%d_%H:%M).log


# stop wildfly server safely
cd $INSTALL_ROOT
./wildfly_safe_stop.sh

# remove all old dwh-j2ee.ears
if [[ -f $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*.ear ]]; then
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
