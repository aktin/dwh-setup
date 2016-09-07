#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-9.0.2.Final



# STEP 1 - Undeploy old Server-EAR via CLI
# if older version existent, then undeploy it
if [ -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.5-SNAPSHOT.ear" ]; then 
	$WILDFLY_HOME/bin/jboss-cli.sh -c --command="undeploy --name=dwh-j2ee-0.5-SNAPSHOT.ear"
fi

# STEP 2 - Deploy new Server-EAR via CLI
# $WILDFLY_HOME/bin/jboss-cli.sh -c --command="deploy --name=$install_root/packages/dwh-j2ee-0.6-SNAPSHOT.ear"
# or with File-based Deployment
if [! -f "$WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.6-SNAPSHOT.ear" ]; then 
	cp $install_root/packages/dwh-j2ee-0.6-SNAPSHOT.ear $WILDFLY_HOME/standalone/deployments/dwh-j2ee-0.6-SNAPSHOT.ear
fi

# STEP 3 - create new mail service
. ./smtp_setup_config.sh

# STEP 4 - Execute Database Scripts
# **** Needs to be run from a folder where the psql-user has read-access ****
# su - postgres bash -c "$install_root/postgres_db_script.sh"

# su - postgres bash -c "psql -d i2b2 -f $install_root/postgres_cleanse_crc_db_script.sql"
./postgres_cleanse.sh