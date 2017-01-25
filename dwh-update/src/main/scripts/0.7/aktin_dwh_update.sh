#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-${wildfly.version}

OLD_EAR=dwh-j2ee-0.6.3.ear
NEW_EAR=dwh-j2ee-0.7-SNAPSHOT.ear

LOGFILE=$install_root/update.log
touch $LOGFILE

echo "AKTIN J2ee update to 0.7" 2>&1 | tee -a $LOGFILE

echo ""
echo "++++++++++++++++++++++" 2>&1 | tee -a $LOGFILE
echo ""


# STEP 1.1 - Create AKTIN Database in postgres for management uses
# TODO check if the database or user exist. if not, then create. if yes. only update. Right now, creating while existing will return error, but continue with the code.
echo "STEP 1.1 create AKTIN database with postgres user" 2>&1 | tee -a $LOGFILE
su - postgres bash -c "$install_root/postgres_db_script.sh" 2>&1 | tee -a $LOGFILE
echo "STEP 1.1 end: database created " 2>&1 | tee -a $LOGFILE

# STEP 1.2 - Create Aktin Data source in wildfly
echo "STEP 1.2 create AKTIN datasource in jboss" 2>&1 | tee -a $LOGFILE

existAktinDS=$( grep -c AktinDS $WILDFLY_HOME/standalone/configuration/standalone.xml)
echo "- $existAktinDS occurences in Standalone.xml found" 2>&1 | tee -a $LOGFILE
if ["$existAktinDS" -gt 0]
then
	$WILDFLY_HOME/bin/jboss-cli.sh  --connect controller=127.0.0.1 --commands="data-source remove --name=AktinDS,/subsystem=datasources:read-resource" 2>&1 | tee -a $LOGFILE
	echo "STEP 1.2.1 end: removed older aktin datasource " 2>&1 | tee -a $LOGFILE
fi
$WILDFLY_HOME/bin/jboss-cli.sh  --connect controller=127.0.0.1 --file=create_aktin_datasource.cli 2>&1 | tee -a $LOGFILE
echo "STEP 1.2.2 end: created aktin datasource" 2>&1 | tee -a $LOGFILE
# $WILDFLY_HOME/bin/jboss-cli.sh  --connect controller=127.0.0.1 --commands="reload" 2>&1 | tee -a $LOGFILE
# echo "STEP 1.2.3 end: reload" 2>&1 | tee -a $LOGFILE

echo ""
echo "++++++++++++++++++++++" 2>&1 | tee -a $LOGFILE
echo ""

# STEP 2 - Undeploy old Server-EAR via CLI
# if older version exists, then undeploy it
echo "STEP 2 Undeploying old DWH EAR file" 2>&1 | tee -a $LOGFILE
if [ -f "$WILDFLY_HOME/standalone/deployments/$OLD_EAR" ] && [ ! -f "$WILDFLY_HOME/standalone/deployments/$OLD_EAR.undeployed" ]; then 
	$WILDFLY_HOME/bin/jboss-cli.sh -c --command="undeploy --name=$OLD_EAR" 2>&1 | tee -a $LOGFILE
	echo "STEP 2 end: undeployed"  2>&1 | tee -a $LOGFILE
else 
	# Keine Undeployment, da keine alte Version gefunden oder bereits undeployed
	echo "STEP 2 fail: not deployed" 2>&1 | tee -a $LOGFILE
fi

# clean up older ears
# rm $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*

echo ""
echo "++++++++++++++++++++++" 2>&1 | tee -a $LOGFILE
echo ""

# STEP 3 - copy new properties to configurations
echo "STEP 3 Deploying new DWH EAR file" 2>&1 | tee -a $LOGFILE
if [ ! -f "$WILDFLY_HOME/standalone/configuration/aktin.properties" ]; then 
	cp $install_root/packages/aktin.properties $WILDFLY_HOME/standalone//configuration/aktin.properties 2>&1 | tee -a $LOGFILE
	echo "STEP 3 end: properties file copied " 2>&1 | tee -a $LOGFILE
else 
	#Kopieren abgebrochen, da die Datei aktin.properties bereits in $WILDFLY_HOME/standalone/configuration/ vorhanden ist.
	echo "STEP 3 fail: properties not copied" 2>&1 | tee -a $LOGFILE
fi

echo ""
echo "++++++++++++++++++++++" 2>&1 | tee -a $LOGFILE
echo ""


# STEP 4 - Deploy new Server-EAR
echo "STEP 4 Deploying new DWH EAR file" 2>&1 | tee -a $LOGFILE
if [ ! -f "$WILDFLY_HOME/standalone/deployments/$NEW_EAR" ]; then 
	# stop wildfly service
	service wildfly stop
	cp $install_root/packages/$NEW_EAR $WILDFLY_HOME/standalone/deployments/ 2>&1 | tee -a $LOGFILE
	echo "STEP 4 end: file deployed " 2>&1 | tee -a $LOGFILE
	# and restart it
	service wildfly start
else 
	# Deployment übersprungen, da die Datei bereits in $WILDFLY_HOME/standalone/deployments/ vorhanden ist.
	echo "STEP 4 fail: file not deployed" 2>&1 | tee -a $LOGFILE
fi

echo ""
echo "++++++++++++++++++++++"  2>&1 | tee -a $LOGFILE
echo ""

# STEP 5 - create new mail service
echo "STEP 5 SMTP Configuration"
. ./smtp_setup_config.sh
echo "STEP 5 end: SMTP configured " 2>&1 | tee -a $LOGFILE

echo ""
echo "++++++++++++++++++++++"  2>&1 | tee -a $LOGFILE
echo ""


echo ""
echo "++++++++++++++++++++++"
echo "Update erfolgreich. Vielen Dank!"
echo ""
