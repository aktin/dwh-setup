#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-9.0.2.Final



# STEP 1 - Undeploy old Server-EAR via CLI
# if older version existent, then undeploy it
echo "Undeploying 0.5 DWH EAR file"
if [ -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.5-SNAPSHOT.ear" ] && [ ! -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.5-SNAPSHOT.ear.undeployed" ]; then 
	$WILDFLY_HOME/bin/jboss-cli.sh -c --command="undeploy --name=dwh-j2ee-0.5-SNAPSHOT.ear"
fi
echo ""
echo "++++++++++++++++++++++"
echo ""
echo "++++++++++++++++++++++"
echo ""

# STEP 2 - Deploy new Server-EAR via CLI
# $WILDFLY_HOME/bin/jboss-cli.sh -c --command="deploy --name=$install_root/packages/dwh-j2ee-0.6-SNAPSHOT.ear"
# or with File-based Deployment
echo "Deploying 0.6 DWH EAR file"
if [ ! -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.6-SNAPSHOT.ear" ]; then 
	cp $install_root/packages/dwh-j2ee-0.6-SNAPSHOT.ear $WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.6-SNAPSHOT.ear
fi
echo ""
echo "++++++++++++++++++++++"
echo ""
echo "++++++++++++++++++++++"
echo ""

# STEP 3 - create new mail service
echo "Set up SMTP"
. ./scripts/smtp_setup_config.sh
echo ""
echo "++++++++++++++++++++++"
echo ""
echo "++++++++++++++++++++++"
echo ""

# STEP 4 - Execute Database Scripts
# **** Needs to be run from a folder where the psql-user has read-access ****
# su - postgres bash -c "$install_root/postgres_db_script.sh"

# su - postgres bash -c "psql -d i2b2 -f $install_root/postgres_cleanse_crc_db_script.sql"
echo "reset Postgres CRC database"
. ./scripts/postgres_cleanse.sh
echo ""
