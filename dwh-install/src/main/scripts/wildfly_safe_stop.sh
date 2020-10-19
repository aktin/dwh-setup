#! /bin/bash

# script to stop wildfly after safely starting it
set -euo pipefail # stop on errors

readonly WILDFLY_DEPLOYMENTS=${path.wildfly.link}/standalone/deployments


# stop wildfly if running
if  [[ $(service wildfly status | grep "not" | wc -l) == 0 ]]; then
	service wildfly stop
fi

# redeploy undeployed .ear of wildfly_safe_start.sh
for i in $(ls $WILDFLY_DEPLOYMENTS | grep ".UNDEPLOYED");
	do 
		mv "$WILDFLY_DEPLOYMENTS/$i" "$WILDFLY_DEPLOYMENTS/${i%.UNDEPLOYED}"; 
	done

