#! /bin/bash

# script to stop wildfly after safely starting it
set -euo pipefail # stop on errors

readonly WILDFLY_HOME=${path.wildfly.link}
readonly JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"
readonly WILDFLY_DEPLOYMENTS=$WILDFLY_HOME/standalone/deployments


# stop wildfly if running
if  [[ $(service wildfly status | grep "not" | wc -l) == 0 ]]; then
	service wildfly stop
fi

# remove undeployed .ear through wildfly_safe_start.sh
if [[ -n $(ls $WILDFLY_DEPLOYMENTS | grep ".ear.undeployed") ]]; then
	rm $WILDFLY_DEPLOYMENTS/*.ear.undeployed
fi
