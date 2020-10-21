#! /bin/bash

readonly INTEGRATION_ROOT=$(pwd)
readonly XML_FILES=$INTEGRATION_ROOT/xml

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}
readonly ORA=${color_orange}
readonly YEL=${color_yellow}
readonly GRE=${color_green}

# destination for query testing
URL="http://localhost:80/webclient/"

# loop over all example querys
XML=( getUserAuth getSchemes getQueryMasterList_fromUserId getCategories getModifiers runQueryInstance_fromQueryDefinition getQueryInstanceList_fromQueryMasterId getQueryResultInstanceList_fromQueryInstanceId getQueryResultInstanceList_fromQueryResultInstanceId )
for i in "${XML[@]}"
do
	# check if response of query contains tag <status type=DONE>, print whole response on failure
	RESPONSE=$(curl -d $XML_FILES/@i2b2_test_$i.xml -s $URL)
	if [ $(echo $RESPONSE | grep -c "<status type=\"DONE\">") == 1 ]; then
		echo -e "${GRE}$i successful${WHI}"
	else
		echo -e "${RED}$i failed${WHI}"
		echo $RESPONSE
	fi
done