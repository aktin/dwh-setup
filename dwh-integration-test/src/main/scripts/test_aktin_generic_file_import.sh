#! /bin/bash

set -euo pipefail

readonly INTEGRATION_ROOT=$(pwd)
readonly INTEGRATION_BINARIES=$INTEGRATION_ROOT/binaries

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}
readonly ORA=${color_orange}
readonly YEL=${color_yellow}
readonly GRE=${color_green}

readonly WHI='\033[0m'
readonly RED='\e[1;31m'
readonly ORA='\e[0;33m'
readonly YEL='\e[1;33m'
readonly GRE='\e[0;32m'

# destination url
URL='http://localhost:80/aktin/admin/rest'

# login into aktin/admin and get bearer-token
BEARER_TOKEN=$(curl -s --location --request POST ''$URL'/auth/login/' --header 'Content-Type: application/json' --data-raw '{ "username": "i2b2", "password": "demouser" }')

# get import scripts
COUNT_SCRIPTS=$(curl -s --location --request GET $URL/script | grep -o 'id' | wc -l)
if [[ $COUNT_SCRIPTS == 5 ]]; then
    echo -e "${GRE}GET scripts successful (GOT $COUNT_SCRIPTS)${WHI}"
else
    echo -e "${RED}GET scripts failed (GOT $COUNT_SCRIPTS)${WHI}"
    echo $(curl -s --request GET $URL/script)
    exit 1
fi

# upload files with all possible scripts
ID_SCRIPTS=( 'error' 'exit' 'sleep' 'success' 'p21import' )
for i in "${!ID_SCRIPTS[@]}"
do
    RESPONSE_CODE=$(curl -s -o /dev/null -w '%{http_code}' --location --request POST ''$URL'/file?scriptId='${ID_SCRIPTS[$i]}'&filename=FILE_'$i'' --data-binary ''$INTEGRATION_BINARIES'/XXXXXXXXXXXXX' --header 'Authorization: Bearer '$BEARER_TOKEN'')
    if [[ $RESPONSE_CODE == 201 ]]; then
	    echo -e "${GRE}UPLOAD of FILE_$i successful ($RESPONSE_CODE)${WHI}"
    else
	    echo -e "${RED}UPLOAD of FILE_$i failed ($RESPONSE_CODE)${WHI}"
	    exit 1
    fi
done

# get uploaded files
COUNT_FILES=$(curl -s --location --request GET ''$URL'/file' | grep -o 'id' | wc -l)
if [[ $COUNT_FILES == 5 ]]; then
    echo -e "${GRE}GET file successful (GOT $COUNT_FILES)${WHI}"
else
    echo -e "${RED}GET file failed (GOT $COUNT_FILES)${WHI}"
    echo $(curl -s --location --request GET $URL/file)
    exit 1
fi

# extract uuid with corresponding script
for i in "${!ID_SCRIPTS[@]}"
do
    declare ID_${ID_SCRIPTS[$i]^^}=$(curl -s --request GET $URL/file | jq '.[] | select(.script=="'${ID_SCRIPTS[$i]}'") | .id' | cut -d "\"" -f 2)
done
UUID_SCRIPTS=( $ID_ERROR $ID_EXIT $ID_SLEEP $ID_SUCCESS $ID_P21IMPORT )

# start file verification of each file
for i in "${!ID_SCRIPTS[@]}"
do
    RESPONSE_CODE=$(curl -s -o /dev/null -w '%{http_code}' --location --request POST ''$URL'/script/'${UUID_SCRIPTS[$i]}'/verify' --header 'Authorization: Bearer '$BEARER_TOKEN'')
    if [[ $RESPONSE_CODE == 204 ]]; then
	    echo -e "${GRE}VERIFY of FILE_$i successful ($RESPONSE_CODE)${WHI}"
    else
	    echo -e "${RED}VERIFY of FILE_$i failed ($RESPONSE_CODE)${WHI}"
	    exit 1
    fi
done

# wait till all scripts are finished
echo "wait 30s"
sleep 30s

# check script processing operation and state
for i in "${!ID_SCRIPTS[@]}"
do
    OPERATION=$(grep '^operation=' /var/lib/aktin/import/${UUID_SCRIPTS[$i]}/properties | cut -d'=' -f2)
    if [[ $OPERATION == 'verifying' ]]; then
        echo -e "${GRE}${UUID_SCRIPTS[$i]} successfully chagend operation to verifying${WHI}"
    else
        echo -e "${RED}${UUID_SCRIPTS[$i]} has operation $OPERATION (should be verifying)${WHI}"
	    exit 1
    fi

    STATE=$(grep '^state=' /var/lib/aktin/import/${UUID_SCRIPTS[$i]}/properties | cut -d'=' -f2)
    case "${ID_SCRIPTS[$i]}" in
    'error' | 'exit')
        if [[ $STATE == 'failed' ]]; then
            echo -e "${GRE}${UUID_SCRIPTS[$i]} successfully chagend state to failed${WHI}"
        else
            echo -e "${RED}${UUID_SCRIPTS[$i]} has state $STATE (should be failed)${WHI}"
	        exit 1
        fi
        ;;
    'sleep')
        if [[ $STATE == 'timeout' ]]; then
            echo -e "${GRE}${UUID_SCRIPTS[$i]} successfully chagend state to timeout${WHI}"
        else
            echo -e "${RED}${UUID_SCRIPTS[$i]} has state $STATE (should be timeout)${WHI}"
	        exit 1
        fi
        ;;
    'success' | 'p21import')
        if [[ $STATE == 'successful' ]]; then
            echo -e "${GRE}${UUID_SCRIPTS[$i]} successfully chagend state to successful${WHI}"
        else
            echo -e "${RED}${UUID_SCRIPTS[$i]} has state $STATE (should be successful)${WHI}"
	        exit 1
        fi
        ;;
    esac
done

# check created logs during script processing via endpoint
PATH_LOG=/var/lib/aktin/import
for i in "${!ID_SCRIPTS[@]}"
do
    if [[ -f $PATH_LOG/${UUID_SCRIPTS[$i]}/stdOutput && -f $PATH_LOG/${UUID_SCRIPTS[$i]}/stdError ]]; then
        echo -e "${GRE}Script logs for ${UUID_SCRIPTS[$i]} found${WHI}"
    else
        echo -e "${RED}No script logs for ${UUID_SCRIPTS[$i]} found${WHI}"
    fi

    LOG_ERROR=$(curl -s --request GET $URL/file/${UUID_SCRIPTS[$i]}/log | jq '.[] | select(.type=="stdError") | .text' | cut -d "\"" -f 2)
    LOG_OUTPUT=$(curl -s --request GET $URL/file/${UUID_SCRIPTS[$i]}/log | jq '.[] | select(.type=="stdOutput") | .text' | cut -d "\"" -f 2)

    case "${ID_SCRIPTS[$i]}" in
    'error' | 'exit')
        if [[ ! -z $LOG_ERROR && -z $LOG_OUTPUT ]]; then
            echo -e "${GRE}${UUID_SCRIPTS[$i]} has an error log and an empty output log${WHI}"
        else
            echo -e "${RED}Something is wrong with the logs of ${UUID_SCRIPTS[$i]}${WHI}"
	        exit 1
        fi
        ;;
    'sleep')
        if [[ -z $LOG_ERROR && -z $LOG_OUTPUT ]]; then
            echo -e "${GRE}${UUID_SCRIPTS[$i]} has empty logs${WHI}"
        else
            echo -e "${RED}Something is wrong with the logs of ${UUID_SCRIPTS[$i]}${WHI}"
	        exit 1
        fi
        ;;
    'success' | 'p21import')
        if [[ -z $LOG_ERROR && ! -z $LOG_OUTPUT ]]; then
            echo -e "${GRE}${UUID_SCRIPTS[$i]} has an output log and an empty error log${WHI}"
        else
            echo -e "${RED}Something is wrong with the logs of ${UUID_SCRIPTS[$i]}${WHI}"
	        exit 1
        fi
        ;;
    esac
done

# check cancelling of file processing
if [[ $(curl -s --request GET $URL/script/queue) == 0 ]]; then
    echo -e "${GRE}Queue is currently empty${WHI}"
else
    echo -e "${ORA}Queue is not empty${WHI}"
fi

RESPONSE_CODE=$(curl -s -o /dev/null -w '%{http_code}' --location --request POST ''$URL'/script/'$ID_SLEEP'/verify' --header 'Authorization: Bearer '$BEARER_TOKEN'')
if [[ $RESPONSE_CODE == 204 ]]; then
    echo -e "${GRE}VERIFY of FILE_$i successful ($RESPONSE_CODE)${WHI}"
else
    echo -e "${RED}VERIFY of FILE_$i failed ($RESPONSE_CODE)${WHI}"
    exit 1
fi

sleep 2s

OPERATION=$(grep '^operation=' /var/lib/aktin/import/$ID_SLEEP/properties | cut -d'=' -f2)
if [[ $OPERATION == 'verifying' ]]; then
    echo -e "${GRE}$ID_SLEEP successfully chagend operation to verifying${WHI}"
else
    echo -e "${ORA}$ID_SLEEP has operation $OPERATION (should be verifying)${WHI}"
fi

STATE=$(grep '^state=' /var/lib/aktin/import/$ID_SLEEP/properties | cut -d'=' -f2)
if [[ $STATE == 'in_progress' ]]; then
    echo -e "${GRE}$ID_SLEEP successfully chagend state to in_progress${WHI}"
else
    echo -e "${ORA}$ID_SLEEP has state $STATE (should be in_progress)${WHI}"
fi

RESPONSE_CODE=$(curl -s -o /dev/null -w '%{http_code}' --location --request POST ''$URL'/script/'$ID_SLEEP'/cancel' --header 'Authorization: Bearer '$BEARER_TOKEN'')
if [[ $RESPONSE_CODE == 204 ]]; then
    echo -e "${GRE}CANCEL of FILE_$i successful ($RESPONSE_CODE)${WHI}"
else
    echo -e "${RED}CANCEL of FILE_$i failed ($RESPONSE_CODE)${WHI}"
    exit 1
fi

STATE=$(grep '^state=' /var/lib/aktin/import/$ID_SLEEP/properties | cut -d'=' -f2)
if [[ $STATE == 'cancelled' ]]; then
    echo -e "${GRE}$ID_SLEEP successfully chagend state to cancelled${WHI}"
else
    echo -e "${ORA}$ID_SLEEP has state $STATE (should be cancelled)${WHI}"
fi

if [[ $(curl -s --request GET $URL/script/queue) == 0 ]]; then
    echo -e "${GRE}Queue is currently empty${WHI}"
else
    echo -e "${RED}Queue is not empty${WHI}"
    exit 1
fi



http://localhost:81/aktin/admin/rest/script/66d70c3f-feb1-4856-93dd-2688b7a03647/import



# delete all uploaded files
for i in "${!ID_SCRIPTS[@]}"
do
    RESPONSE_CODE=$(curl -s -o /dev/null -w '%{http_code}' --location --request DELETE ''$URL'/file/'${UUID_SCRIPTS[$i]}'' --header 'Authorization: Bearer '$BEARER_TOKEN'')
    if [[ $RESPONSE_CODE == 204 ]]; then
	    echo -e "${GRE}DELETE of FILE_$i successful ($RESPONSE_CODE)${WHI}"
    else
	    echo -e "${RED}DELETE of FILE_$i failed ($RESPONSE_CODE)${WHI}"
	    exit 1
    fi
done

# check via endpoint
COUNT_FILES=$(curl -s --location --request GET ''$URL'/file' | grep -o 'id' | wc -l)
if [[ $COUNT_FILES == 0 ]]; then
    echo -e "${GRE}GET file successful (GOT $COUNT_FILES)${WHI}"
else
    echo -e "${RED}GET file failed (GOT $COUNT_FILES)${WHI}"
    echo $(curl -s --location --request GET $URL/file)
    exit 1
fi

# check via folder
if [ -z $(ls -A /var/lib/aktin/import) ]; then
    echo -e "${GRE}/var/lib/aktin/import is emtpy${WHI}"
else
    echo -e "${RED}/var/lib/aktin/import is not emtpy${WHI}"
    exit 1
fi
