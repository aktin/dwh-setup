#! /bin/bash

# script to stop wildfly after safely starting it
set -euo pipefail # stop on errors

readonly WILDFLY_DEPLOYMENTS=/opt/wildfly/standalone/deployments


# stop wildfly if running
if systemctl is-active --quiet wildfly; then
	service wildfly stop
fi

# redeploy undeployed .ear of wildfly_safe_start.sh
for i in $(ls $WILDFLY_DEPLOYMENTS | grep ".UNDEPLOYED");
	do
		mv "$WILDFLY_DEPLOYMENTS/$i" "$WILDFLY_DEPLOYMENTS/${i%.UNDEPLOYED}";
	done
