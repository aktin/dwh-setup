#! /bin/bash

# colors for console output
readonly WHI=${color.white}
readonly RED=${color.red}
readonly ORA=${color.orange}
readonly YEL=${color.yellow}
readonly GRE=${color.green}

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