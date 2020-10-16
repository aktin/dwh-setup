#! /bin/bash

set -euo pipefail # stop on errors

# colors for console output
WHI='\033[0m'
RED='\e[1;31m'
ORA='\e[0;33m'
YEL='\e[1;33m'
GRE='\e[0;32m'

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



echo
echo -e "${YEL}+++++ STEP I +++++ Integration test I2B2${WHI}"
echo

# Test 1 : a basic query
# destination for query testing
URL="http://localhost:80/webclient/"

# loop over all example querys
XML=( getUserAuth getSchemes getQueryMasterList_fromUserId getCategories getModifiers runQueryInstance_fromQueryDefinition getQueryInstanceList_fromQueryMasterId getQueryResultInstanceList_fromQueryInstanceId getQueryResultInstanceList_fromQueryResultInstanceId )
for i in  "${XML[@]}"
do
	# check if response of query contains tag <status type=DONE>, print whole response on failure
	RESPONSE=$(curl -d @i2b2_test_$i.xml -s $URL)
	if [ $(echo $RESPONSE | grep -c "<status type=\"DONE\">") == 1 ]; then
		echo -e "${GRE}$i successful${WHI}"
	else
		echo -e "${RED}$i failed${WHI}"
		echo $RESPONSE
	fi
done



echo
echo -e "${YEL}+++++ STEP II +++++ Integration test AKTIN${WHI}"
echo

# Test 1 : CDA import
# destination url for fhir testing
URL="http://localhost:80/aktin/cda/fhir/Binary/"

# set timestamp to compare saving of sent CDA files
CURRENT_TIME=$(date "+%Y-%m-%d %H")

# loop over all storyboards
STORYBOARD=( aktin_test_storyboard01.xml aktin_test_storyboard01.xml aktin_test_storyboard01_error.xml aktin_test_storyboard02.xml aktin_test_storyboard03.xml )
CODE=( 201 200 422 201 201 )
for i in "${!STORYBOARD[@]}"
do
	# sent CDA document via java-demo-server-fhir-client and catch response
	RESPONSE=$(java -Djava.util.logging.config.file="$(pwd)/logging.properties" -cp "$(pwd)/demo-server-0.13.jar" org.aktin.cda.etl.demo.client.FhirClient $URL ${STORYBOARD[$i]} 2<&1)
	
	# extract response code and compare with predefined code, print whole response on failure
	RESPONSE_CODE=$(echo $RESPONSE | grep -oP '(?<=Response code: )[0-9]+')
	if [[ $RESPONSE_CODE == ${CODE[$i]} ]]; then
		echo -e "${GRE}${STORYBOARD[$i]} successful ($RESPONSE_CODE)${WHI}"
	else
		echo -e "${RED}${STORYBOARD[$i]} failed ($RESPONSE_CODE)${WHI}"
		echo $RESPONSE
	fi
done

# count entries in i2b2crcdata with import_date within previously set timestamp
if [[ $(sudo -u postgres psql -d i2b2 -v ON_ERROR_STOP=1 -c "SELECT import_date FROM i2b2crcdata.encounter_mapping" | grep -c "$CURRENT_TIME") != 0 ]]; then
	echo -e "${GRE} --> new entries in i2b2 detected${WHI}"
else
	echo -e "${RED} --> no new entries in i2b2 detected${WHI}"
fi

# Test 2 : plain modules
# destination url for plain testing
URL="http://localhost:80/aktin/admin/rest/test/"

# loop over modules broker, email an R
MODULE=( "broker/status" "email/send" "r/run" )
for i in "${MODULE[@]}"
do
	# broker is get request, other modules are post requests
	if [[ $i == "broker/status" ]]; then
		RESPONSE_CODE=$(curl -o /dev/null -w "%{http_code}" -s --request GET $URL$i)
	else
		RESPONSE_CODE=$(curl -o /dev/null -w "%{http_code}" -s --request POST $URL$i)
	fi

	# check response for code 200, print whole response on failure (via new request)
	if [[ $RESPONSE_CODE == 200 ]]; then
		echo -e "${GRE}Test $i successful ($RESPONSE_CODE)${WHI}"
	else
		echo -e "${RED}Test $i ($RESPONSE_CODE)${WHI}"
		if [[ $i == "broker/status" ]]; then
			echo $(curl -s --request GET $URL$i)
		else
			echo $(curl -s --request POST $URL$i)
		fi
	fi
done


# Test 3 : consent-manager
# login into aktin/admin and get bearer-token
BEARER_TOKEN=$(curl -s --location --request POST 'http://localhost:80/aktin/admin/rest/auth/login/' --header 'Content-Type: application/json' --data-raw '{ "username": "i2b2", "password": "demouser" }')

# create random string and number
RANDOM_STRING=$(echo $(cat /dev/urandom | tr -dc 'a-zA-Z' | fold -w 6 | head -n 1))
RANDOM_NUMBER=$(echo $(cat /dev/urandom | tr -dc '0-9' | fold -w 6 | head -n 1))

# try post on aktin/admin/consentManager via token and get response code
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" --location --request POST 'http://localhost:80/aktin/admin/rest/optin/ENQUIRE/Patient/1.2.276.0.76.4.8/'$RANDOM_NUMBER'' --header 'Authorization: Bearer '$BEARER_TOKEN'' --header 'Content-Type: application/json' --data-raw '{ "opt": 0, "sic": "", "comment": "'$RANDOM_STRING'" }')

# check if response code is 200, print whole response on failure (via new request)
if [[ $RESPONSE_CODE == 200 || $RESPONSE_CODE == 201 ]]; then
	echo -e "${GRE}Test consent-manager successful ($RESPONSE_CODE)${WHI}"
else
	echo -e "${RED}Test consent-manager ($RESPONSE_CODE)${WHI}"
	echo $(curl -s --location --request POST 'http://localhost:80/aktin/admin/rest/optin/ENQUIRE/Patient/1.2.276.0.76.4.8/'$RANDOM_NUMBER'' --header 'Authorization: Bearer '$BEARER_TOKEN'' --header 'Content-Type: application/json' --data-raw '{ "opt": 0, "sic": "", "comment": "'$RANDOM_STRING'" }')
fi
