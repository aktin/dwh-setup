#!/bin/bash

# script to test i2b2 and aktin installation on ubuntu 20.04
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>
set -euo pipefail

readonly INTEGRATION_ROOT=$(pwd)
readonly SQL_FILES=$INTEGRATION_ROOT/sql

# colors for console output
readonly WHI=${color.white}
readonly RED=${color.red}
readonly ORA=${color.orange}
readonly YEL=${color.yellow}
readonly GRE=${color.green}

# make all test skripts executable
chmod +x *

# run dwh-install with dwh-update
tar xvzf packages/dwh-install-*.tar.gz
cd aktin-dwh-installer
./aktin_install.sh


# if not running, start apache2, postgresql and wildfly service
if  [[ $(service apache2 status | grep "not" | wc -l) == 1 ]]; then
	service apache2 start
fi
if  [[ $(service postgresql status | grep "down" | wc -l) == 1 ]]; then
	service postgresql start
fi
if  [[ $(service wildfly status | grep "not" | wc -l) == 1 ]]; then
	service wildfly start
fi


if [[ -n $(cat /var/www/html/webclient/i2b2_config_data.js | grep "debug: false") ]]; then

# activacte i2b2 webclient debugging
sed -i 's|debug: false|debug: true|' /var/www/html/webclient/i2b2_config_data.js

# set ports of apache2 to all IP adresses
sed -i 's/Listen 80/Listen 0.0.0.0:80/' /etc/apache2/ports.conf
sed -i 's/Listen 443/Listen 0.0.0.0:443/g' /etc/apache2/ports.conf

# add i2b2 demo data
sudo -u postgres psql -d i2b2 -f $SQL_FILES/i2b2_db_demo.sql
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

# test plain modules
./test_aktin_plain.sh

# test consent-manager
./test_aktin_consent_manager.sh

