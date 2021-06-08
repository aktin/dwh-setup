#! /bin/bash

# script to safely start wildfly
set -euo pipefail # stop on errors

readonly WILDFLY_DEPLOYMENTS=/opt/wildfly/standalone/deployments


# start wildfly if not running
if ! systemctl is-active --quiet wildfly; then

	#  undeploy dwh.ear prior starting to prevent crash
	for i in $(ls $WILDFLY_DEPLOYMENTS | grep "dwh-j2ee-*.");
		do
			mv "$WILDFLY_DEPLOYMENTS/$i" "$WILDFLY_DEPLOYMENTS/$i.UNDEPLOYED";
		done
	service wildfly start
fi
