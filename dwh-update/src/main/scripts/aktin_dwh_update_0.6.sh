#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-9.0.2.Final

LOGFILE=$install_root/update.log
touch $LOGFILE

# STEP 1 - Undeploy old Server-EAR via CLI
# if older version exists, then undeploy it
echo "Undeploying 0.5 DWH EAR file"
if [ -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.5-SNAPSHOT.ear" ] && [ ! -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.5-SNAPSHOT.ear.undeployed" ]; then 
	echo "STEP 1"  >> $LOGFILE
	$WILDFLY_HOME/bin/jboss-cli.sh -c --command="undeploy --name=dwh-j2ee-0.5-SNAPSHOT.ear" >> $LOGFILE

	echo ""
	echo "++++++++++++++++++++++"
	echo ""

	# STEP 1.1 - Execute Database Scripts
	echo "STEP 1.1 reset Postgres CRC database"
	. ./postgres_cleanse.sh >> $LOGFILE
	echo ""

	# STEP 1.2 - Ontologien
	echo "STEP 1.2 update Ontologien"
	. ./pestgres_update_ontology.sh >> $LOGFILE
	echo ""

else 
	echo "STEP 1 not deployed" >> $LOGFILE
	echo "Undeployment und SQL Skript übersprungen, da keine alte Version gefunden oder bereits undeployed"
fi
echo ""
echo "++++++++++++++++++++++"
echo ""
# STEP 2 - Deploy new Server-EAR
echo "Deploying 0.6 DWH EAR file"
if [ ! -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.6-SNAPSHOT.ear" ]; then 
	cp $install_root/packages/dwh-j2ee-0.6-SNAPSHOT.ear $WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.6-SNAPSHOT.ear
	echo "STEP 2 file copied " >> $LOGFILE
else 
	echo "STEP 2 not copied" >> $LOGFILE
	echo "Deployment übersprungen, da die Datei bereits in $WILDFLY_HOME/standalone/deployments/ vorhanden ist."
fi
# echo ""
# echo "++++++++++++++++++++++"
# echo ""
# # STEP 3 - create new mail service
# echo "SMTP Configuration"
# . ./smtp_setup_config.sh

echo ""
echo "++++++++++++++++++++++"
echo ""
# STEP 4 - Remove data from Login form
echo "Removing standard data from Login Form"
i2b2_WEBDIR=/var/webroot/webclient
if [ ! -f $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig ]; then 
	cp $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig
	echo "STEP 4 file backed up" >> $LOGFILE
fi
sed -i "s/name=\"uname\" id=\"loginusr\" value=\"demo\"/name=\"uname\" id=\"loginusr\" value=\"\"/g; s/name=\"pword\" id=\"loginpass\" value=\"demouser\"/name=\"pword\" id=\"loginpass\" value=\"\"/g" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js
echo "STEP 4 replaced" >> $LOGFILE

echo ""
echo "++++++++++++++++++++++"
echo "Update auf 0.6 erfolgreich. Vielen Dank!"
echo ""
