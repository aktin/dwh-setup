#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-${wildfly.version}

# copy aktin.properties into the wildfly configuration folder
if [ ! -f "$WILDFLY_HOME/standalone/configuration/aktin.properties" ]; then 
	# Hinweis zu properties Aenderungen.
	echo +++WARNING+++ Please modify the file $install_root/aktin.properties with
	echo nano $install_root/aktin.properties 
	echo and copy it to the configuration folder of wildfy with
	echo "cp -v $install_root/aktin.properties $WILDFLY_HOME/standalone/configuration/aktin.properties"
	echo 
	echo This script will exit now. Please restart it once the properties file is copied. 
	echo "+++INFO+++ Please apply later changes to $WILDFLY_HOME/standalone/configuration/aktin.properties "
	echo "and then either restart this script"

	exit 127 # controlled interrupt if properties still not copied
else 
	# kein Kopieren, da die Datei aktin.properties bereits in $WILDFLY_HOME/standalone/configuration/ vorhanden ist.
	# merge beide files wenn möglich - later
	# TODO check for missing properties in wildlfy properties with each new update. 
	#if missing merge active file into the current one (changes in active file take priority) and exit script
	# awk -F= '!a[$1]++' a1.properties a2.properties
	echo aktin.properties already present,  not copied | tee -a $LOGFILE
fi
