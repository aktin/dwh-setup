#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-${wildfly.version}

OLD_EAR=dwh-j2ee-${ear.old.version}.ear
NEW_EAR=dwh-j2ee-${ear.version}.ear

LOGFILE=$install_root/update.log
touch $LOGFILE

# STEP 1 - Undeploy old Server-EAR via CLI
# if older version exists, then undeploy it
echo "Undeploying old DWH EAR file" 2>&1 | tee -a $LOGFILE
if [ -f "$WILDFLY_HOME/standalone/deployments/$OLD_EAR" ] && [ ! -f "$WILDFLY_HOME/standalone/deployments/$OLD_EAR.undeployed" ]; then 
	echo "STEP 1"  2>&1 | tee -a $LOGFILE
	$WILDFLY_HOME/bin/jboss-cli.sh -c --command="undeploy --name=$OLD_EAR" 2>&1 | tee -a $LOGFILE

	echo ""
	echo "++++++++++++++++++++++" 2>&1 | tee -a $LOGFILE
	echo ""

	# STEP 1.1 - Execute Database Scripts
	echo "STEP 1.1 Reset i2b2 CRC database" 2>&1 | tee -a $LOGFILE
	. ./postgres_cleanse.sh 2>&1 | tee -a $LOGFILE
	echo ""

	# STEP 1.2 - Ontologien
	echo "STEP 1.2 update i2b2 Ontology Cell Data" 2>&1 | tee -a $LOGFILE
	. ./postgres_update_ontology.sh 2>&1 | tee -a $LOGFILE
	echo ""

else 
	echo "STEP 1 not deployed" 2>&1 | tee -a $LOGFILE
	echo "Undeployment und SQL Skript übersprungen, da keine alte Version gefunden oder bereits undeployed"
fi
echo ""
echo "++++++++++++++++++++++" 2>&1 | tee -a $LOGFILE
echo ""
# STEP 2 - Deploy new Server-EAR
echo "Deploying new DWH EAR file" 2>&1 | tee -a $LOGFILE
if [ ! -f "$WILDFLY_HOME/standalone/deployments/$NEW_EAR" ]; then 
	cp $install_root/packages/$NEW_EAR $WILDFLY_HOME/standalone/deployments/
	echo "STEP 2 file copied " 2>&1 | tee -a $LOGFILE
else 
	echo "STEP 2 not copied" 2>&1 | tee -a $LOGFILE
	echo "Deployment übersprungen, da die Datei bereits in $WILDFLY_HOME/standalone/deployments/ vorhanden ist."
fi
# echo ""
# echo "++++++++++++++++++++++"
# echo ""
# # STEP 3 - create new mail service
# echo "SMTP Configuration"
# . ./smtp_setup_config.sh

echo ""
echo "++++++++++++++++++++++"  2>&1 | tee -a $LOGFILE
echo ""
# STEP 4 - Remove data from Login form
echo "Removing standard data from Login Form" 2>&1 | tee -a $LOGFILE
i2b2_WEBDIR=/var/webroot/webclient
if [ ! -f $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig ]; then 
	cp $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig
	echo "STEP 4 Webclient PM file backed up" 2>&1 | tee -a $LOGFILE
fi
sed -i "s/name=\"uname\" id=\"loginusr\" value=\"demo\"/name=\"uname\" id=\"loginusr\" value=\"\"/g; s/name=\"pword\" id=\"loginpass\" value=\"demouser\"/name=\"pword\" id=\"loginpass\" value=\"\"/g" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js
echo "STEP 4 values replaced" 2>&1 | tee -a $LOGFILE

echo ""
echo "++++++++++++++++++++++"
echo "Update erfolgreich. Vielen Dank!"
echo ""