#!/usr/bin/env bash

# Initial parameters
SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")
WILDFLY_HOME=/opt/wildfly-9.0.2.Final

# check whether console parameter was given. use -y to avoid prompt
prompt=true
if [ $# -eq 0 ] || [ $1 != "y" ];	then
	prompt=true
else
	prompt=false
fi

# STEP 1 - Undeploy old Server-EAR
# via CLI
$WILDFLY_HOME/bin/jboss-cli.sh -c --command="undeploy --name=dwh-j2ee-0.5-SNAPSHOT.ear"

#STEP 2 - Execute Database Scripts
# **** Needs to be run from a folder where the psql-user has read-access ****
echo cleanse postgres i2b2 database crc tables
# su - postgres bash -c "$install_root/postgres_db_script.sh"
su - postgres bash -c "psql -d i2b2 -f $install_root/postgres_cleanse_crc_db_script.sql"


# STEP 3 - Deploy new Server-EAR
#via CLI
#/opt/wildfly-9.0.2.Final/bin/jboss-cli.sh -c --command="deploy --name=./dwh-j2ee-0.6-SNAPSHOT.ear"
#for some reason the CLI deployment does not work

#File-based Deployment
cp $install_root/packages/dwh-j2ee-0.6-SNAPSHOT.ear /opt/wildfly-9.0.2.Final/standalone/deployments/dwh-j2ee-0.6-SNAPSHOT.ear


# STEP 4 - create new mail service
./step_4_config_smtp_mail.sh