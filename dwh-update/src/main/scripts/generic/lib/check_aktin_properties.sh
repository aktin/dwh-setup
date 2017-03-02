#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-${wildfly.version}

# copy aktin.properties into the wildfly configuration folder
if [ ! -f "$WILDFLY_HOME/standalone/configuration/aktin.properties" ]; then 
	# Hinweis zu properties Aenderungen.
	echo +++WARNING+++ Bitte die Einstellungen in der Datei $install_root/aktin.properties ändern mittels: 
	echo     nano $install_root/aktin.properties 
	echo und anschließend nach dem Wildfly Konfigurationsordner kopieren mittels:
	echo "    cp -v $install_root/aktin.properties $WILDFLY_HOME/standalone/configuration/aktin.properties"
	echo 
	echo Dieser Skript wird nun beendet. 
	echo Nach obiger Änderungen starten Sie dieses Skript bitte neu.
	echo "+++INFO+++ Spätere Änderungen bitte direkt in $WILDFLY_HOME/standalone/configuration/aktin.properties vornehmen"
	echo "   und dann dieses Skript dann erneut ausführen"

	exit 124 # controlled interrupt if properties still not copied
else 
	# kein Kopieren, da die Datei aktin.properties bereits in $WILDFLY_HOME/standalone/configuration/ vorhanden ist.
	# merge beide files wenn möglich - later
	# TODO check for missing properties in wildlfy properties with each new update. 
	#if missing merge active file into the current one (changes in active file take priority) and exit script
	# awk -F= '!a[$1]++' a1.properties a2.properties
	echo aktin.properties bereits vorhanden. | tee -a $LOGFILE
fi
