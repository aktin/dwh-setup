#! /bin/bash

# script to safely start wildfly
set -euo pipefail # stop on errors

readonly WILDFLY_DEPLOYMENTS=${path.wildfly.link}/standalone/deployments


# start wildfly if not running
if  [[ $(service wildfly status | grep "not" | wc -l) == 1 ]]; then

	# if postgresql is not running: undeploy dwh.ear prior starting to prevent crash 
	if  [[ $(service postgresql status | grep "down" | wc -l) == 1 ]]; then
		for i in $(ls $WILDFLY_DEPLOYMENTS | grep "dwh-j2ee-*.");
			do
				mv "$WILDFLY_DEPLOYMENTS/$i" "$WILDFLY_DEPLOYMENTS/$i.UNDEPLOYED";
			done
		service wildfly start
	else	
		service wildfly start
	fi
fi
