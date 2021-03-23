#!/bin/bash

# script to test i2b2 and aktin installation on ubuntu 20.04
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
set -euo pipefail

readonly INTEGRATION_ROOT=$(pwd)
readonly SQL_FILES=$INTEGRATION_ROOT/sql
readonly SCRIPTS=$INTEGRATION_ROOT/scripts

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}
readonly ORA=${color_orange}
readonly YEL=${color_yellow}
readonly GRE=${color_green}

# make all test skripts executable
chmod +x *

# run dwh-install with dwh-update
tar xvzf packages/dwh-install-*.tar.gz
cd aktin-dwh-installer
./aktin_install.sh


# if not running, start apache2, postgresql and wildfly service
if ! systemctl is-active --quiet apache2; then
	service apache2 start
fi
if ! systemctl is-active --quiet postgresql; then
	service postgresql start
fi
if ! systemctl is-active --quiet wildfly; then
	service wildfly start
fi


if [[ -n $(cat /var/www/html/webclient/i2b2_config_data.js | grep "debug: false") ]]; then

# copy aktin.properties in wildfly configuration folder
echo "COPY aktin.properties"
cd $INTEGRATION_ROOT
cp aktin-dwh-installer/dwh-update/aktin.properties /opt/wildfly/standalone/configuration/

# activacte i2b2 webclient debugging
echo "ACTIVATE debugging"
sed -i 's|debug: false|debug: true|' /var/www/html/webclient/i2b2_config_data.js

# set ports of apache2 to all IP adresses
echo "CHANGE ports"
sed -i 's/Listen 80/Listen 0.0.0.0:80/' /etc/apache2/ports.conf
sed -i 's/Listen 443/Listen 0.0.0.0:443/g' /etc/apache2/ports.conf

# add i2b2 demo data
echo "ADD db_demo"
cp $SQL_FILES/i2b2_db_demo.sql /tmp/
sudo -u postgres psql -d i2b2 -f /tmp/i2b2_db_demo.sql
rm /tmp/i2b2_db_demo.sql

# move integration test scripts to import-scripts
echo "MOVE SCRIPTS"
cp $SCRIPTS/* /var/lib/aktin/import-scripts/

# set script timeout in aktin.properties to 10s
echo "SET SCRIPT TIMEOUT"
sed -i 's|import.script.check.interval=.*|import.script.check.interval=10000|'  /opt/wildfly/standalone/configuration/aktin.properties

# restart wildfly to apply changes
echo "WILDFLY restart"
service wildfly restart
fi


cd $INTEGRATION_ROOT

echo
echo -e "${YEL}+++++ STEP I +++++ Integration test I2B2${WHI}"
echo

# test a basic query in i2b2
./test_i2b2_query.sh

echo
echo -e "${YEL}+++++ STEP II +++++ Integration test AKTIN${WHI}"
echo

# test CDA import
./test_aktin_cda_import.sh
echo

# test plain modules
./test_aktin_plain.sh
echo

# test consent-manager
./test_aktin_consent_manager.sh

echo
echo -e "${YEL}+++++ STEP III +++++ Integration test postgresql${WHI}"
echo

# test background-validation
./test_postgresql_background_validation.sh

echo
echo -e "${YEL}+++++ STEP IV +++++ Integration test p21 endpoints${WHI}"
echo

# test generic-file-import endpoints and script operations
./test_aktin_generic_file_import.sh
