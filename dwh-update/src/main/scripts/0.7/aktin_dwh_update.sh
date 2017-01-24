#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-${wildfly.version}

OLD_EAR=dwh-j2ee-0.6.3.ear
NEW_EAR=dwh-j2ee-0.7-SNAPSHOT.ear

LOGFILE=$install_root/update.log
touch $LOGFILE





# STEP 1.1 - Create AKTIN Database in postgres for management uses

echo "create AKTIN database with postgres user"
su - postgres bash -c "$install_root/postgres_db_script.sh"



# STEP 1.2 - Create Aktin Data source in wildfly
echo "create AKTIN datasource in jboss"
$WILDFLY_HOME/bin/jboss-cli.sh  --connect controller=127.0.0.1 --file=create_aktin_datassource.cli




# # STEP 4 - Remove data from Login form
# echo "Removing standard data from Login Form" 2>&1 | tee -a $LOGFILE
# i2b2_WEBDIR=/var/webroot/webclient
# if [ ! -f $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig ]; then 
# 	cp $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js.orig
# 	echo "STEP 4 Webclient PM file backed up" 2>&1 | tee -a $LOGFILE
# fi
# sed -i "s/name=\"uname\" id=\"loginusr\" value=\"demo\"/name=\"uname\" id=\"loginusr\" value=\"\"/g; s/name=\"pword\" id=\"loginpass\" value=\"demouser\"/name=\"pword\" id=\"loginpass\" value=\"\"/g" $i2b2_WEBDIR/js-i2b2/cells/PM/PM_misc.js
# echo "STEP 4 values replaced" 2>&1 | tee -a $LOGFILE



# STEP 2 - Undeploy old Server-EAR via CLI
# if older version exists, then undeploy it
echo "Undeploying old DWH EAR file" 2>&1 | tee -a $LOGFILE
if [ -f "$WILDFLY_HOME/standalone/deployments/$OLD_EAR" ] && [ ! -f "$WILDFLY_HOME/standalone/deployments/$OLD_EAR.undeployed" ]; then 
	echo "STEP 2"  2>&1 | tee -a $LOGFILE
	$WILDFLY_HOME/bin/jboss-cli.sh -c --command="undeploy --name=$OLD_EAR" 2>&1 | tee -a $LOGFILE
else 
	echo "STEP 2 not deployed" 2>&1 | tee -a $LOGFILE
	echo "Undeployment, da keine alte Version gefunden oder bereits undeployed"
fi

# clean up older ears
# rm $WILDFLY_HOME/standalone/deployments/dwh-j2ee-*

echo ""
echo "++++++++++++++++++++++" 2>&1 | tee -a $LOGFILE
echo ""








# STEP 3 - copy new properties to configurations
echo "Deploying new DWH EAR file" 2>&1 | tee -a $LOGFILE
if [ ! -f "$WILDFLY_HOME/standalone/configuration/aktin.properties" ]; then 
	cp $install_root/packages/aktin.properties $WILDFLY_HOME/standalone//configuration/aktin.properties 2>&1 | tee -a $LOGFILE
	echo "STEP 3 properties file copied " 2>&1 | tee -a $LOGFILE
else 
	echo "STEP 3 properties not copied" 2>&1 | tee -a $LOGFILE
	echo "Kopieren abgebrochen, da die Datei aktin.properties bereits in $WILDFLY_HOME/standalone/configuration/ vorhanden ist."
fi

echo ""
echo "++++++++++++++++++++++" 2>&1 | tee -a $LOGFILE
echo ""


# STEP 4 - Deploy new Server-EAR
echo "Deploying new DWH EAR file" 2>&1 | tee -a $LOGFILE
if [ ! -f "$WILDFLY_HOME/standalone/deployments/$NEW_EAR" ]; then 
	# stop wildfly service
	service wildfly stop
	cp $install_root/packages/$NEW_EAR $WILDFLY_HOME/standalone/deployments/ 2>&1 | tee -a $LOGFILE
	echo "STEP 4 file copied " 2>&1 | tee -a $LOGFILE
	# and restart it
	service wildfly start
else 
	echo "STEP 4 not copied" 2>&1 | tee -a $LOGFILE
	echo "Deployment übersprungen, da die Datei bereits in $WILDFLY_HOME/standalone/deployments/ vorhanden ist."
fi
echo ""
echo "++++++++++++++++++++++"
echo ""

# STEP 5 - create new mail service
echo "SMTP Configuration"
. ./smtp_setup_config.sh

echo ""
echo "++++++++++++++++++++++"  2>&1 | tee -a $LOGFILE
echo ""


echo ""
echo "++++++++++++++++++++++"
echo "Update erfolgreich. Vielen Dank!"
echo ""
