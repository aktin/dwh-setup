#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
INSTALL_ROOT=$(dirname "$(dirname "$SCRIPT")")
WILDFLY_HOME=/opt/wildfly-${wildfly.version}

RCol='\e[0m'; Red='\e[0;31m'; BRed='\e[1;31m'; Yel='\e[0;33m'; BYel='\e[1;33m'; Gre='\e[0;32m'; BGre='\e[1;32m'; Blu='\e[0;34m'; BBlu='\e[1;34m'; 

# copy aktin.properties into the wildfly configuration folder
if [ ! -f "$WILDFLY_HOME/standalone/configuration/aktin.properties" ]; then 
	# Hinweis zu properties Aenderungen.
	echo -e "${BYel}+++WARNING+++ ${RCol}Bitte die Einstellungen in der Datei $INSTALL_ROOT/aktin.properties ändern mittels: "
	echo -e "${Gre}    nano $INSTALL_ROOT/aktin.properties${RCol}"
	echo und anschließend nach dem Wildfly Konfigurationsordner kopieren mittels:
	echo -e "${Gre}    cp -v $INSTALL_ROOT/aktin.properties $WILDFLY_HOME/standalone/configuration/aktin.properties${RCol}"
	echo 
	echo Dieser Skript wird nun beendet. 
	echo Nach obiger Änderungen starten Sie dieses Skript bitte neu.
	echo -e "${BYel}+++INFO+++${RCol} Spätere Änderungen bitte direkt in $WILDFLY_HOME/standalone/configuration/aktin.properties vornehmen"
	echo "   und dann das Updateskript dann erneut ausführen"
	echo "-------------------------"
	echo 
	exit 124 # controlled interrupt if properties still not copied
else 
	# kein Kopieren, da die Datei aktin.properties bereits in $WILDFLY_HOME/standalone/configuration/ vorhanden ist.
	# merge beide files wenn möglich - later
	# TODO check for missing properties in wildlfy properties with each new update. 
	#if missing merge active file into the current one (changes in active file take priority) and exit script
	# awk -F= '!a[$1]++' a1.properties a2.properties
	echo aktin.properties bereits vorhanden. | tee -a $LOGFILE
fi
