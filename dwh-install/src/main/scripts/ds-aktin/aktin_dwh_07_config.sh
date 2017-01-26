#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-${wildfly.version}
JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"

OLD_EAR=dwh-j2ee-0.6.3.ear
NEW_EAR=dwh-j2ee-0.7-SNAPSHOT.ear

LOGFILE=$install_root/update.log
touch $LOGFILE
echo -e "\n++++++++++++++++++++++\n\n"
echo "AKTIN J2ee changes for 0.7"

echo -e "\n++++++++++++++++++++++\n\n"


# STEP 1.1 - Create AKTIN Database in postgres for management uses
# TODO check if the database or user exist. if not, then create. if yes. only update. Right now, creating while existing will return error, but continue with the code.
echo "STEP 1.1 create AKTIN database with postgres user"
su - postgres bash -c "$install_root/postgres_db_script.sh"
echo "STEP 1.1 end: database created "

echo -e "\n++++++++++++++++++++++\n\n"

# STEP 1.2 - Create Aktin Data source in wildfly
echo "STEP 1.2 create AKTIN datasource in jboss"

existAktinDS=$( grep -c AktinDS $WILDFLY_HOME/standalone/configuration/standalone.xml)
echo "- $existAktinDS occurences of AKTINDS in Standalone.xml found"
if [ "$existAktinDS" -gt 0 ]
then
	$JBOSSCLI "data-source remove --name=AktinDS,/subsystem=datasources:read-resource"
	echo "STEP 1.2.1 end: removed older aktin datasource "
fi
$JBOSSCLI --file=create_aktin_datasource.cli
echo "STEP 1.2.2 end: created aktin datasource"
# $WILDFLY_HOME/bin/jboss-cli.sh  --connect controller=127.0.0.1 --commands="reload"
# echo "STEP 1.2.3 end: reload"


echo -e "\n++++++++++++++++++++++\n\n"

# STEP 2 - copy new properties to configurations
echo "STEP 2 Move aktin.properties into the wildfly configuration folder"
if [ ! -f "$WILDFLY_HOME/standalone/configuration/aktin.properties" ]; then 
	cp $install_root/aktin.properties $WILDFLY_HOME/standalone/configuration/aktin.properties
	echo "STEP 2 end: properties file copied "
else 
	#Kopieren abgebrochen, da die Datei aktin.properties bereits in $WILDFLY_HOME/standalone/configuration/ vorhanden ist.
	echo "STEP 2 fail: properties not copied"
fi

echo -e "\n++++++++++++++++++++++\n\n"

# STEP 3 - create new mail service
echo "STEP 3 SMTP Configuration"
. $install_root/smtp_setup_config.sh
echo "STEP 3 end: SMTP configured "

echo -e "\n++++++++++++++++++++++\n\n"
