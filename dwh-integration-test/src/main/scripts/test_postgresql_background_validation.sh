#! /bin/bash

set -euo pipefail

readonly INTEGRATION_ROOT=$(pwd)
readonly XML_FILES=$INTEGRATION_ROOT/xml

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}
readonly ORA=${color_orange}
readonly YEL=${color_yellow}
readonly GRE=${color_green}

# stop postgresql if running
if systemctl is-active --quiet postgresql; then
	echo "Stopping Postgresql"
	echo
	service postgresql stop
fi

# run test_aktin_consent_manager.sh with offline postgresql (expected to fail)
BEARER_TOKEN=$(curl -s --location --request POST 'http://localhost:80/aktin/admin/rest/auth/login/' --header 'Content-Type: application/json' --data-raw '{ "username": "i2b2", "password": "demouser" }')
RANDOM_STRING=$(echo $(cat /dev/urandom | tr -dc 'a-zA-Z' | fold -w 6 | head -n 1))
RANDOM_NUMBER=$(echo $(cat /dev/urandom | tr -dc '0-9' | fold -w 6 | head -n 1))
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" --location --request POST 'http://localhost:80/aktin/admin/rest/optin/AKTIN/Patient/1.2.276.0.76.4.8/'$RANDOM_NUMBER'' --header 'Authorization: Bearer '$BEARER_TOKEN'' --header 'Content-Type: application/json' --data-raw '{ "opt": 1, "sic": "", "comment": "'$RANDOM_STRING'" }')
if [[ $RESPONSE_CODE == 400 || $RESPONSE_CODE == 401 ]]; then
	echo -e "${GRE}Test consent-manager successfully failed ($RESPONSE_CODE)${WHI}"
else
	echo -e "${RED}Test consent-manager ($RESPONSE_CODE)${WHI}"
	echo $(curl -s --location --request POST 'http://localhost:80/aktin/admin/rest/optin/AKTIN/Patient/1.2.276.0.76.4.8/'$RANDOM_NUMBER'' --header 'Authorization: Bearer '$BEARER_TOKEN'' --header 'Content-Type: application/json' --data-raw '{ "opt": 1, "sic": "", "comment": "'$RANDOM_STRING'" }')
fi
echo

# restart postgresql and run tests again (expected to succeed)
echo "Starting Postgresql"
service postgresql start
echo

echo "Sleep for 90s"
sleep 90
echo

./test_aktin_consent_manager.sh
