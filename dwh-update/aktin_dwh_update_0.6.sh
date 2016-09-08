#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-9.0.2.Final


# STEP 1 - Undeploy old Server-EAR via CLI
# if older version exists, then undeploy it
echo "Undeploying 0.5 DWH EAR file"
if [ -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.5-SNAPSHOT.ear" ] && [ ! -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.5-SNAPSHOT.ear.undeployed" ]; then 
	$WILDFLY_HOME/bin/jboss-cli.sh -c --command="undeploy --name=dwh-j2ee-0.5-SNAPSHOT.ear"

	echo ""
	echo "++++++++++++++++++++++"
	echo ""

	# STEP 4 - Execute Database Scripts
	echo "reset Postgres CRC database"
	. ./scripts/postgres_cleanse.sh
	echo ""
else 
	echo "Undeployment und SQL Skript übersprungen, da keine alte Version gefunden oder bereits undeployed"
fi
echo ""
echo "++++++++++++++++++++++"
echo ""
echo "++++++++++++++++++++++"
echo ""
# STEP 2 - Deploy new Server-EAR
echo "Deploying 0.6 DWH EAR file"
if [ ! -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.6-SNAPSHOT.ear" ]; then 
	cp $install_root/packages/dwh-j2ee-0.6-SNAPSHOT.ear $WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.6-SNAPSHOT.ear
else 
	echo "Deployment übersprungen, da die Datei bereits in $WILDFLY_HOME/standalone/deployments/ vorhanden ist."
fi
# echo ""
# echo "++++++++++++++++++++++"
# echo ""
# echo "++++++++++++++++++++++"
# echo ""
# # STEP 3 - create new mail service
# echo "SMTP Configuration"
# . ./scripts/smtp_setup_config.sh

echo ""
echo "++++++++++++++++++++++"
echo "Update auf 0.6 erfolgreich. Vielen Dank"
echo ""