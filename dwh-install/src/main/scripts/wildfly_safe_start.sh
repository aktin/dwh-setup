#! /bin/bash

# script to safely start wildfly
set -euo pipefail # stop on errors

readonly WILDFLY_HOME=${path.wildfly.link}
readonly JBOSSCLI="$WILDFLY_HOME/bin/jboss-cli.sh -c"
readonly WILDFLY_DEPLOYMENTS=$WILDFLY_HOME/standalone/deployments


# start wildfly if not running
if  [[ $(service wildfly status | grep "not" | wc -l) == 1 ]]; then

	# if postgresql is not running: undeploy dwh.ear prior starting to prevent crash 
	if  [[ $(service postgresql status | grep "down" | wc -l) == 1 ]]; then
		$JBOSSCLI --command="undeploy --name=dwh-j2ee*.ear"
		service wildfly start
	else	
		service wildfly start
	fi
fi
